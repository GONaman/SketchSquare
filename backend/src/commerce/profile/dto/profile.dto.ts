import { ApiHideProperty } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import {
  IsEmpty,
  IsIn,
  IsNotEmpty,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
} from 'class-validator';

export const AVATAR_CONTENT_TYPES = [
  'image/jpeg',
  'image/png',
  'image/webp',
] as const;

const trim = ({ value }: { value: unknown }): unknown =>
  typeof value === 'string' ? value.trim() : value;

export class UpdateProfileDto {
  @IsOptional()
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.replace(/[\s\-()]/g, '') : value,
  )
  @Matches(/^\+?[0-9]{10,14}$/, {
    message: 'phone must be 10-14 digits, optionally starting with +',
  })
  phone?: string;

  @IsOptional()
  @Transform(trim)
  @IsString()
  @IsNotEmpty()
  @MaxLength(100)
  city?: string;

  // Declared only so the response says "cannot be changed" instead of a generic "should not exist".
  @ApiHideProperty()
  @IsEmpty({ message: 'fullName cannot be changed' })
  fullName?: never;

  @ApiHideProperty()
  @IsEmpty({ message: 'address cannot be changed' })
  address?: never;
}

export class AvatarUploadUrlDto {
  @IsIn(AVATAR_CONTENT_TYPES)
  contentType!: (typeof AVATAR_CONTENT_TYPES)[number];
}

export class AvatarConfirmDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(200)
  objectKey!: string;
}
