import { IsNotEmpty, IsString, MaxLength } from 'class-validator';

export class VerifyPaymentDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(100)
  razorpayOrderId!: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(100)
  razorpayPaymentId!: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(200)
  razorpaySignature!: string;
}

export class StubCompleteDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(100)
  orderId!: string;
}
