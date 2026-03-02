import { Request, Response, NextFunction } from 'express';
import { authService } from './service';
import {
  registerSchema,
  loginSchema,
  refreshSchema,
  forgotPasswordSchema,
  resetPasswordSchema,
} from './validators';
import { AppError } from '../../middleware/errorHandler';

export const authController = {
  async register(req: Request, res: Response, next: NextFunction) {
    try {
      const data = registerSchema.parse(req.body);
      const result = await authService.register(data);
      res.status(201).json({ success: true, data: result });
    } catch (err) {
      if (err instanceof AppError) return next(err);
      if ((err as any)?.issues) {
        return next(new AppError(400, 'VALIDATION_ERROR', 'Dados inválidos', (err as any).issues));
      }
      next(err);
    }
  },

  async login(req: Request, res: Response, next: NextFunction) {
    try {
      const data = loginSchema.parse(req.body);
      const result = await authService.login(data.email, data.password);
      res.status(200).json({ success: true, data: result });
    } catch (err) {
      if (err instanceof AppError) return next(err);
      if ((err as any)?.issues) {
        return next(new AppError(400, 'VALIDATION_ERROR', 'Dados inválidos', (err as any).issues));
      }
      next(err);
    }
  },

  async refresh(req: Request, res: Response, next: NextFunction) {
    try {
      const data = refreshSchema.parse(req.body);
      const result = await authService.refresh(data.refreshToken);
      res.status(200).json({ success: true, data: result });
    } catch (err) {
      if (err instanceof AppError) return next(err);
      if ((err as any)?.issues) {
        return next(new AppError(400, 'VALIDATION_ERROR', 'Dados inválidos', (err as any).issues));
      }
      next(err);
    }
  },

  async forgotPassword(req: Request, res: Response, next: NextFunction) {
    try {
      const data = forgotPasswordSchema.parse(req.body);
      const result = await authService.forgotPassword(data.email);
      res.status(200).json({ success: true, data: result });
    } catch (err) {
      if (err instanceof AppError) return next(err);
      if ((err as any)?.issues) {
        return next(new AppError(400, 'VALIDATION_ERROR', 'Dados inválidos', (err as any).issues));
      }
      next(err);
    }
  },

  async resetPassword(req: Request, res: Response, next: NextFunction) {
    try {
      const data = resetPasswordSchema.parse(req.body);
      const result = await authService.resetPassword(data.token, data.password);
      res.status(200).json({ success: true, data: result });
    } catch (err) {
      if (err instanceof AppError) return next(err);
      if ((err as any)?.issues) {
        return next(new AppError(400, 'VALIDATION_ERROR', 'Dados inválidos', (err as any).issues));
      }
      next(err);
    }
  },

  async me(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as any).user?.userId;
      if (!userId) {
        return next(new AppError(401, 'UNAUTHORIZED', 'Não autorizado'));
      }
      const result = await authService.getMe(userId);
      res.status(200).json({ success: true, data: result });
    } catch (err) {
      next(err);
    }
  },
};
