import { Transform } from 'class-transformer';
import {
  IsEmail,
  IsNotEmpty,
  IsString,
  Matches,
  MaxLength,
  MinLength,
} from 'class-validator';

const trim = ({ value }: { value: unknown }) =>
  typeof value === 'string' ? value.trim() : value;
const normalizeEmail = ({ value }: { value: unknown }) =>
  typeof value === 'string' ? value.trim().toLowerCase() : value;

export class SignupDto {
  @Transform(normalizeEmail) @IsEmail() @MaxLength(254) email!: string;
  @IsString() @MinLength(8) @MaxLength(128) password!: string;
  @Transform(trim) @IsString() @IsNotEmpty() @MaxLength(100) fullName!: string;
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.replace(/[\s\-()]/g, '') : value,
  )
  @Matches(/^\+?[0-9]{10,14}$/, {
    message: 'phone must be 10-14 digits, optionally starting with +',
  })
  phone!: string;
  @Transform(trim) @IsString() @IsNotEmpty() @MaxLength(300) address!: string;
  @Transform(trim) @IsString() @IsNotEmpty() @MaxLength(100) city!: string;
}

export class LoginDto {
  @Transform(normalizeEmail) @IsEmail() email!: string;
  @IsString() @IsNotEmpty() @MaxLength(128) password!: string;
}

export class RefreshDto {
  @IsString() @IsNotEmpty() @MaxLength(512) refreshToken!: string;
}

export class ForgotPasswordDto {
  @Transform(normalizeEmail) @IsEmail() email!: string;
}

export class ResetPasswordDto {
  @IsString() @IsNotEmpty() @MaxLength(512) token!: string;
  @IsString() @MinLength(8) @MaxLength(128) newPassword!: string;
}
