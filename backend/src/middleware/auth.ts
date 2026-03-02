import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { env } from '../config/env';
import prisma from '../config/database';
import { AppError } from './errorHandler';

interface JwtPayload {
  userId: string;
  companyId: string;
  role: string;
  sessionVersion: number;
}

declare global {
  namespace Express {
    interface Request {
      user?: JwtPayload;
    }
  }
}

export function authenticate(req: Request, _res: Response, next: NextFunction) {
  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith('Bearer ')) {
    return next(new AppError(401, 'UNAUTHORIZED', 'Token de autenticação não fornecido'));
  }

  const token = authHeader.split(' ')[1];

  try {
    const payload = jwt.verify(token, env.JWT_SECRET) as JwtPayload;
    req.user = payload;
    next();
  } catch {
    next(new AppError(401, 'INVALID_TOKEN', 'Token inválido ou expirado'));
  }
}

export async function validateSession(req: Request, _res: Response, next: NextFunction) {
  if (!req.user) {
    return next(new AppError(401, 'UNAUTHORIZED', 'Não autorizado'));
  }

  const user = await prisma.user.findUnique({
    where: { id: req.user.userId },
    select: { sessionVersion: true, status: true },
  });

  if (!user || user.status === 'inactive') {
    return next(new AppError(401, 'ACCOUNT_INACTIVE', 'Conta desativada'));
  }

  if (user.sessionVersion !== req.user.sessionVersion) {
    return next(new AppError(401, 'SESSION_EXPIRED', 'Sessão expirada. Faça login novamente'));
  }

  next();
}

export function authorize(roles: string[]) {
  return (req: Request, _res: Response, next: NextFunction) => {
    if (!req.user) {
      return next(new AppError(401, 'UNAUTHORIZED', 'Não autorizado'));
    }
    if (!roles.includes(req.user.role)) {
      return next(new AppError(403, 'FORBIDDEN', 'Você não tem permissão para esta ação'));
    }
    next();
  };
}
