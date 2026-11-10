import { CanActivate, ExecutionContext, Injectable, UnauthorizedException } from '@nestjs/common';
import { loadConfig } from '../config/configuration';

// Phase 1 auth posture:
//  - Dev (FIREBASE_AUTH_ENABLED=false): requests carry `x-user-id`. NEVER ship this to production.
//  - Production (Phase 2): Firebase ID-token verification slots in here —
//    the guard is the single place that changes; services only see req.userId.
@Injectable()
export class AuthGuard implements CanActivate {
  canActivate(ctx: ExecutionContext): boolean {
    const req = ctx.switchToHttp().getRequest();
    const cfg = loadConfig();
    if (!cfg.firebaseAuthEnabled) {
      const userId = req.headers['x-user-id'];
      if (!userId) throw new UnauthorizedException('Missing x-user-id (dev auth)');
      req.userId = String(userId);
      return true;
    }
    // Firebase verification is wired in Phase 2 with the app; until then fail closed.
    throw new UnauthorizedException('Firebase auth enabled but verifier not yet wired (Phase 2)');
  }
}
