import {
  Body,
  Controller,
  Get,
  Post,
  UploadedFile,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiBearerAuth, ApiBody, ApiConsumes, ApiTags } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { memoryStorage } from 'multer';
import { AllowUnverified } from '../common/decorators/access.decorators';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { MAX_DOCUMENT_BYTES } from './document-type';
import { SubmitVerificationDto } from './dto/verification.dto';
import { VerificationService } from './verification.service';

@ApiTags('verification')
@ApiBearerAuth()
@AllowUnverified()
@Controller('verification')
export class VerificationController {
  constructor(private readonly verification: VerificationService) {}

  @Post()
  @Throttle({ default: { limit: 10, ttl: 60_000 } })
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      required: ['coaRegistrationNumber', 'document'],
      properties: {
        coaRegistrationNumber: { type: 'string' },
        document: {
          type: 'string',
          format: 'binary',
          description: 'PDF/JPG/PNG, max 10MB',
        },
      },
    },
  })
  @UseInterceptors(
    FileInterceptor('document', {
      storage: memoryStorage(),
      limits: { fileSize: MAX_DOCUMENT_BYTES, files: 1 },
    }),
  )
  submit(
    @CurrentUser('id') userId: string,
    @Body() dto: SubmitVerificationDto,
    @UploadedFile() file: Express.Multer.File | undefined,
  ) {
    return this.verification.submit(userId, dto.coaRegistrationNumber, file);
  }

  @Get('me')
  mine(@CurrentUser('id') userId: string) {
    return this.verification.mine(userId);
  }
}
