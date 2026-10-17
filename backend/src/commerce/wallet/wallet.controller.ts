import { Body, Controller, Get, HttpCode, Post, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import {
  type AuthUser,
  CurrentUser,
} from '../../common/decorators/current-user.decorator';
import { Page, PageQueryDto } from '../../common/pagination';
import { BankAccountDto, CreateWithdrawalDto } from './dto/wallet.dto';
import {
  BankAccountView,
  LedgerItem,
  WalletService,
  WalletView,
  WithdrawalView,
} from './wallet.service';

@ApiTags('wallet')
@ApiBearerAuth()
@Controller('wallet')
export class WalletController {
  constructor(private readonly wallet: WalletService) {}

  @Get()
  get(@CurrentUser() user: AuthUser): Promise<WalletView> {
    return this.wallet.getWallet(user.id);
  }

  @Get('ledger')
  ledger(
    @CurrentUser() user: AuthUser,
    @Query() query: PageQueryDto,
  ): Promise<Page<LedgerItem>> {
    return this.wallet.listLedger(user.id, query.cursor, query.limit);
  }

  @Post('bank-account')
  @HttpCode(200)
  @Throttle({ default: { limit: 10, ttl: 60_000 } })
  bankAccount(
    @CurrentUser() user: AuthUser,
    @Body() dto: BankAccountDto,
  ): Promise<BankAccountView> {
    return this.wallet.upsertBankAccount(user.id, dto);
  }

  @Post('withdrawals')
  @Throttle({ default: { limit: 10, ttl: 60_000 } })
  withdraw(
    @CurrentUser() user: AuthUser,
    @Body() dto: CreateWithdrawalDto,
  ): Promise<WithdrawalView> {
    return this.wallet.requestWithdrawal(user.id, dto.amountPaise);
  }

  @Get('withdrawals')
  withdrawals(
    @CurrentUser() user: AuthUser,
    @Query() query: PageQueryDto,
  ): Promise<Page<WithdrawalView>> {
    return this.wallet.listWithdrawals(user.id, query.cursor, query.limit);
  }
}
