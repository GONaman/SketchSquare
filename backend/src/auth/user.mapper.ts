import { User } from '@prisma/client';

/** Contract `User` shape (docs/API_CONTRACT.md). Never exposes passwordHash. */
export function toUserResponse(user: User, freeDownloadLimit: number) {
  return {
    id: user.id,
    email: user.email,
    fullName: user.fullName,
    address: user.address,
    phone: user.phone,
    avatarUrl: user.avatarUrl,
    city: user.city,
    role: user.role,
    verificationStatus: user.verificationStatus,
    architectRating: user.architectRating,
    freeDownloadsUsed: user.freeDownloadsUsed,
    freeDownloadLimit,
    createdAt: user.createdAt,
  };
}
