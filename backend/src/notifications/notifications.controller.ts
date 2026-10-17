import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Post,
  Query,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { AllowUnverified } from '../common/decorators/access.decorators';
import {
  type AuthUser,
  CurrentUser,
} from '../common/decorators/current-user.decorator';
import { PageQueryDto } from '../common/pagination';
import { DeviceTokensService } from './device-tokens.service';
import {
  MarkReadDto,
  RegisterDeviceTokenDto,
  RemoveDeviceTokenDto,
} from './dto/notifications.dto';
import {
  NotificationPage,
  NotificationsService,
} from './notifications.service';

// `[auth]`: unverified users must be able to register a device and receive their verification result.
@ApiTags('notifications')
@ApiBearerAuth()
@AllowUnverified()
@Controller('me')
export class NotificationsController {
  constructor(
    private readonly devices: DeviceTokensService,
    private readonly notifications: NotificationsService,
  ) {}

  // `devices` is an alias of the contract path `device-tokens`.
  @Post(['device-tokens', 'devices'])
  @HttpCode(204)
  @ApiOperation({ summary: 'Register (or re-assign) a push device token' })
  register(
    @CurrentUser() user: AuthUser,
    @Body() dto: RegisterDeviceTokenDto,
  ): Promise<void> {
    return this.devices.register(user.id, dto.token, dto.platform);
  }

  @Delete(['device-tokens', 'devices'])
  @HttpCode(204)
  @ApiOperation({ summary: 'Unregister a push device token (e.g. on logout)' })
  unregister(
    @CurrentUser() user: AuthUser,
    @Body() dto: RemoveDeviceTokenDto,
  ): Promise<void> {
    return this.devices.remove(user.id, dto.token);
  }

  @Get('notifications')
  @ApiOperation({
    summary: 'In-app notifications, newest first, with the unread count',
  })
  list(
    @CurrentUser() user: AuthUser,
    @Query() query: PageQueryDto,
  ): Promise<NotificationPage> {
    return this.notifications.list(user.id, query);
  }

  @Post('notifications/read')
  @HttpCode(204)
  @ApiOperation({ summary: 'Mark notifications as read (all if no ids given)' })
  read(@CurrentUser() user: AuthUser, @Body() dto: MarkReadDto): Promise<void> {
    return this.notifications.markRead(user.id, dto.ids);
  }
}
