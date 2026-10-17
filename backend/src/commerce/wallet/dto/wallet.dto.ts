import { Transform } from 'class-transformer';
import { IsInt, IsString, Length, Matches, Max, Min } from 'class-validator';

const trim = ({ value }: { value: unknown }): unknown =>
  typeof value === 'string' ? value.trim() : value;

export class BankAccountDto {
  @Transform(trim)
  @IsString()
  @Length(2, 100)
  holderName!: string;

  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim().toUpperCase() : value,
  )
  @Matches(/^[A-Z]{4}0[A-Z0-9]{6}$/, {
    message: 'ifsc must be a valid IFSC code',
  })
  ifsc!: string;

  @Transform(trim)
  @Matches(/^\d{9,18}$/, { message: 'accountNumber must be 9–18 digits' })
  accountNumber!: string;
}

export class CreateWithdrawalDto {
  @IsInt()
  @Min(1)
  @Max(2_000_000_000)
  amountPaise!: number;
}
