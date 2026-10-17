import { Body, Controller, Get, HttpCode, Patch, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { AllowUnverified } from '../../common/decorators/access.decorators';
import {
  type AuthUser,
  CurrentUser,
} from '../../common/decorators/current-user.decorator';
import {
  AvatarConfirmDto,
  AvatarUploadUrlDto,
  UpdateProfileDto,
} from './dto/profile.dto';
import { ProfileService, UserResponse } from './profile.service';

/** The caller's own profile. Available to any signed-in user, including those still awaiting verification. */
@ApiTags('profile')
@ApiBearerAuth()
@AllowUnverified()
@Controller('me')
export class ProfileController {
  constructor(private readonly profile: ProfileService) {}

  @Get()
  get(@CurrentUser() user: AuthUser): Promise<UserResponse> {
    return this.profile.get(user.id);
  }

  @Patch()
  update(
    @CurrentUser() user: AuthUser,
    @Body() dto: UpdateProfileDto,
  ): Promise<UserResponse> {
    return this.profile.update(user.id, dto);
  }

  @Post('avatar/upload-url')
  @HttpCode(200)
  avatarUploadUrl(
    @CurrentUser() user: AuthUser,
    @Body() dto: AvatarUploadUrlDto,
  ) {
    return this.profile.avatarUploadUrl(user.id, dto);
  }

  @Post('avatar/confirm')
  @HttpCode(200)
  @Throttle({ write: { limit: 10, ttl: 60_000 } })
  confirmAvatar(
    @CurrentUser() user: AuthUser,
    @Body() dto: AvatarConfirmDto,
  ): Promise<UserResponse> {
    return this.profile.confirmAvatar(user.id, dto.objectKey);
  }
}
