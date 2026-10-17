import { HttpStatus, Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { randomUUID } from 'node:crypto';
import sharp from 'sharp';
import { toUserResponse } from '../../auth/user.mapper';
import { ApiException } from '../../common/errors/api-exception';
import { Env } from '../../config/env.schema';
import { PrismaService } from '../../prisma/prisma.service';
import { StorageService } from '../../storage/storage.service';
import type { AvatarUploadUrlDto, UpdateProfileDto } from './dto/profile.dto';

export const AVATAR_MAX_BYTES = 5 * 1024 * 1024;
export const AVATAR_SIZE_PX = 512;
const EXTENSIONS: Record<string, string> = {
  'image/jpeg': 'jpg',
  'image/png': 'png',
  'image/webp': 'webp',
};
const ALLOWED_FORMATS = new Set(['jpeg', 'png', 'webp']);
const MAX_INPUT_PIXELS = 40_000_000;

export type UserResponse = ReturnType<typeof toUserResponse>;

@Injectable()
export class ProfileService {
  private readonly logger = new Logger(ProfileService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly storage: StorageService,
    private readonly config: ConfigService<Env, true>,
  ) {}

  async get(userId: string): Promise<UserResponse> {
    const user = await this.prisma.user.findUniqueOrThrow({
      where: { id: userId },
    });
    return this.respond(user);
  }

  /** Only phone and city are editable; name and address are part of the verified identity. */
  async update(userId: string, dto: UpdateProfileDto): Promise<UserResponse> {
    if (dto.phone === undefined && dto.city === undefined) {
      throw new ApiException(
        HttpStatus.BAD_REQUEST,
        'VALIDATION_ERROR',
        'Provide phone and/or city',
      );
    }
    const user = await this.prisma.user.update({
      where: { id: userId },
      data: { phone: dto.phone, city: dto.city },
    });
    return this.respond(user);
  }

  async avatarUploadUrl(
    userId: string,
    dto: AvatarUploadUrlDto,
  ): Promise<{
    uploadUrl: string;
    objectKey: string;
    headers: Record<string, string>;
  }> {
    const objectKey = `${avatarUploadPrefix(userId)}${randomUUID()}.${EXTENSIONS[dto.contentType]}`;
    // The length is not known up front, so it is enforced when the upload is confirmed.
    const { uploadUrl, headers } = await this.storage.presignOriginalUpload({
      key: objectKey,
      contentType: dto.contentType,
    });
    return { uploadUrl, objectKey, headers };
  }

  async confirmAvatar(
    userId: string,
    objectKey: string,
  ): Promise<UserResponse> {
    const keyPattern = new RegExp(
      `^${avatarUploadPrefix(userId)}[0-9a-f-]{36}\\.(jpg|png|webp)$`,
    );
    if (!keyPattern.test(objectKey)) {
      throw new ApiException(
        HttpStatus.BAD_REQUEST,
        'VALIDATION_ERROR',
        'objectKey is not a valid avatar upload',
      );
    }
    const head = await this.storage.headOriginal(objectKey);
    if (!head) {
      throw new ApiException(
        HttpStatus.BAD_REQUEST,
        'VALIDATION_ERROR',
        'Upload not found; upload the image first',
      );
    }
    if (head.sizeBytes > AVATAR_MAX_BYTES) {
      await this.discard(objectKey);
      throw new ApiException(
        HttpStatus.BAD_REQUEST,
        'VALIDATION_ERROR',
        'Image is too large (max 5 MB)',
      );
    }

    const raw = await this.storage.getOriginalBuffer(objectKey);
    let png: Buffer;
    try {
      // Content is judged by decoding, not by the client-declared type; EXIF is stripped by the re-encode.
      const image = sharp(raw, { limitInputPixels: MAX_INPUT_PIXELS });
      const meta = await image.metadata();
      if (!meta.format || !ALLOWED_FORMATS.has(meta.format)) {
        throw new Error(`unsupported format ${String(meta.format)}`);
      }
      png = await image
        .rotate()
        .resize(AVATAR_SIZE_PX, AVATAR_SIZE_PX, { fit: 'cover' })
        .png()
        .toBuffer();
    } catch (err) {
      await this.discard(objectKey);
      this.logger.warn(
        `Rejected avatar upload for ${userId}: ${err instanceof Error ? err.message : String(err)}`,
      );
      throw new ApiException(
        HttpStatus.BAD_REQUEST,
        'VALIDATION_ERROR',
        'The file is not a valid JPG, PNG or WebP image',
      );
    }

    // A fresh key per avatar: previews are cached as immutable, so a changed picture needs a new URL.
    const previewKey = `avatars/${userId}/${randomUUID()}.png`;
    await this.storage.putPreview(previewKey, png);
    const user = await this.prisma.user.update({
      where: { id: userId },
      data: { avatarUrl: this.storage.previewUrl(previewKey) },
    });
    await this.discard(objectKey);
    return this.respond(user);
  }

  private respond(user: Parameters<typeof toUserResponse>[0]): UserResponse {
    return toUserResponse(
      user,
      this.config.get('FREE_DOWNLOAD_LIMIT', { infer: true }),
    );
  }

  private async discard(objectKey: string): Promise<void> {
    try {
      await this.storage.deleteOriginal(objectKey);
    } catch (err) {
      this.logger.warn(
        `Could not delete ${objectKey}: ${err instanceof Error ? err.message : String(err)}`,
      );
    }
  }
}

function avatarUploadPrefix(userId: string): string {
  return `avatar-uploads/${userId}/`;
}
