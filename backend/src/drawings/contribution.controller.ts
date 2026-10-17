import { Controller, Get } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import {
  ContributionService,
  ContributionStatus,
} from './contribution.service';

@ApiTags('drawings')
@ApiBearerAuth()
@Controller('me')
export class ContributionController {
  constructor(private readonly contribution: ContributionService) {}

  @Get('contribution-status')
  status(@CurrentUser('id') userId: string): Promise<ContributionStatus> {
    return this.contribution.status(userId);
  }
}
