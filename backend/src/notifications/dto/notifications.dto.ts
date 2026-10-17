import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsIn,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  MinLength,
} from 'class-validator';

export const DEVICE_PLATFORMS = ['android', 'ios', 'web'] as const;
export type DevicePlatform = (typeof DEVICE_PLATFORMS)[number];

export class RegisterDeviceTokenDto {
  @ApiProperty({ description: 'FCM registration token' })
  @IsString()
  @MinLength(10)
  @MaxLength(4096)
  token!: string;

  @ApiProperty({ enum: DEVICE_PLATFORMS })
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.toLowerCase() : value,
  )
  @IsIn(DEVICE_PLATFORMS)
  platform!: DevicePlatform;
}

export class RemoveDeviceTokenDto {
  @ApiProperty()
  @IsString()
  @MinLength(10)
  @MaxLength(4096)
  token!: string;
}

export class MarkReadDto {
  @ApiPropertyOptional({
    type: [String],
    description: 'Notification ids to mark as read; omit to mark all as read',
  })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(100)
  @IsUUID('all', { each: true })
  ids?: string[];
}
