import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import crypto from 'crypto';
import prisma from '../../config/database';
import { env } from '../../config/env';
import { AppError } from '../../middleware/errorHandler';

const JWT_EXPIRY = '24h';
const REFRESH_EXPIRY = '7d';
const BCRYPT_ROUNDS = 12;

interface TokenPayload {
  userId: string;
  companyId: string;
  role: string;
  sessionVersion: number;
}

function generateTokens(payload: TokenPayload) {
  const accessToken = jwt.sign(payload, env.JWT_SECRET, { expiresIn: JWT_EXPIRY });
  const refreshToken = jwt.sign(payload, env.JWT_REFRESH_SECRET, { expiresIn: REFRESH_EXPIRY });
  return { accessToken, refreshToken };
}

export const authService = {
  async register(data: {
    companyName: string;
    cnpj: string;
    name: string;
    email: string;
    password: string;
  }) {
    // Check if email already exists
    const existingUser = await prisma.user.findUnique({ where: { email: data.email } });
    if (existingUser) {
      throw new AppError(409, 'EMAIL_EXISTS', 'Este email já está cadastrado');
    }

    // Check if CNPJ already exists
    const existingCompany = await prisma.company.findUnique({ where: { cnpj: data.cnpj } });
    if (existingCompany) {
      throw new AppError(409, 'CNPJ_EXISTS', 'Este CNPJ já está cadastrado');
    }

    // Get Basic plan
    const basicPlan = await prisma.plan.findFirst({ where: { name: 'Basic' } });
    if (!basicPlan) {
      throw new AppError(500, 'PLAN_NOT_FOUND', 'Plano básico não encontrado');
    }

    // Create company
    const company = await prisma.company.create({
      data: {
        name: data.companyName,
        cnpj: data.cnpj,
        planId: basicPlan.id,
      },
    });

    // Create admin user
    const passwordHash = await bcrypt.hash(data.password, BCRYPT_ROUNDS);
    const user = await prisma.user.create({
      data: {
        companyId: company.id,
        email: data.email,
        passwordHash,
        name: data.name,
        role: 'admin',
        status: 'active',
      },
    });

    const tokens = generateTokens({
      userId: user.id,
      companyId: company.id,
      role: user.role,
      sessionVersion: user.sessionVersion,
    });

    return {
      user: { id: user.id, name: user.name, email: user.email, role: user.role },
      company: { id: company.id, name: company.name },
      ...tokens,
    };
  },

  async login(email: string, password: string) {
    const user = await prisma.user.findUnique({
      where: { email },
      include: { company: true },
    });

    if (!user) {
      throw new AppError(401, 'INVALID_CREDENTIALS', 'Email ou senha inválidos');
    }

    if (user.status === 'inactive') {
      throw new AppError(403, 'ACCOUNT_INACTIVE', 'Conta desativada. Entre em contato com o administrador');
    }

    const isValid = await bcrypt.compare(password, user.passwordHash);
    if (!isValid) {
      throw new AppError(401, 'INVALID_CREDENTIALS', 'Email ou senha inválidos');
    }

    // Update last login
    await prisma.user.update({
      where: { id: user.id },
      data: { lastLoginAt: new Date() },
    });

    const tokens = generateTokens({
      userId: user.id,
      companyId: user.companyId,
      role: user.role,
      sessionVersion: user.sessionVersion,
    });

    return {
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
        companyId: user.companyId,
      },
      company: { id: user.company.id, name: user.company.name },
      ...tokens,
    };
  },

  async refresh(refreshToken: string) {
    try {
      const payload = jwt.verify(refreshToken, env.JWT_REFRESH_SECRET) as TokenPayload;

      const user = await prisma.user.findUnique({
        where: { id: payload.userId },
        include: { company: true },
      });

      if (!user || user.status === 'inactive') {
        throw new AppError(401, 'INVALID_TOKEN', 'Token inválido');
      }

      // Check session version (force logout invalidates old tokens)
      if (user.sessionVersion !== payload.sessionVersion) {
        throw new AppError(401, 'SESSION_EXPIRED', 'Sessão expirada. Faça login novamente');
      }

      const tokens = generateTokens({
        userId: user.id,
        companyId: user.companyId,
        role: user.role,
        sessionVersion: user.sessionVersion,
      });

      return {
        user: {
          id: user.id,
          name: user.name,
          email: user.email,
          role: user.role,
          companyId: user.companyId,
        },
        ...tokens,
      };
    } catch (err) {
      if (err instanceof AppError) throw err;
      throw new AppError(401, 'INVALID_TOKEN', 'Token inválido ou expirado');
    }
  },

  async forgotPassword(email: string) {
    const user = await prisma.user.findUnique({ where: { email } });
    if (!user) {
      // Don't reveal if email exists
      return { message: 'Se o email existir, enviaremos instruções de recuperação' };
    }

    const resetToken = crypto.randomUUID();
    const resetExpiresAt = new Date(Date.now() + 60 * 60 * 1000); // 1 hour

    await prisma.user.update({
      where: { id: user.id },
      data: { resetToken, resetExpiresAt },
    });

    // TODO: Send email with reset link via Resend
    console.log(`[MOCK EMAIL] Reset token for ${email}: ${resetToken}`);

    return { message: 'Se o email existir, enviaremos instruções de recuperação' };
  },

  async resetPassword(token: string, newPassword: string) {
    const user = await prisma.user.findFirst({
      where: {
        resetToken: token,
        resetExpiresAt: { gt: new Date() },
      },
    });

    if (!user) {
      throw new AppError(400, 'INVALID_TOKEN', 'Token inválido ou expirado');
    }

    const passwordHash = await bcrypt.hash(newPassword, BCRYPT_ROUNDS);

    await prisma.user.update({
      where: { id: user.id },
      data: {
        passwordHash,
        resetToken: null,
        resetExpiresAt: null,
        sessionVersion: user.sessionVersion + 1, // Invalidate old sessions
      },
    });

    return { message: 'Senha alterada com sucesso' };
  },

  async getMe(userId: string) {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: {
        company: {
          include: { plan: true },
        },
      },
    });

    if (!user) {
      throw new AppError(404, 'USER_NOT_FOUND', 'Usuário não encontrado');
    }

    return {
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      status: user.status,
      companyId: user.companyId,
      company: {
        id: user.company.id,
        name: user.company.name,
        plan: user.company.plan.name,
      },
      lastLoginAt: user.lastLoginAt,
    };
  },
};
