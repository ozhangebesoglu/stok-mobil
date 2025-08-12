import jwt from "jsonwebtoken";
import bcrypt from "bcrypt";

const JWT_SECRET = process.env.NEXTAUTH_SECRET || "dev-secret";
const TOKEN_EXPIRES_IN = "7d";

export type JwtPayload = {
  sub: number;
  email: string;
  rol: string;
};

export async function verifyPassword(plain: string, hash: string): Promise<boolean> {
  return bcrypt.compare(plain, hash);
}

export function signToken(payload: JwtPayload): string {
  return jwt.sign(payload, JWT_SECRET, { expiresIn: TOKEN_EXPIRES_IN });
}

export function verifyToken(token: string): JwtPayload | null {
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    if (typeof decoded === 'string') return null;
    const payload = decoded as Partial<JwtPayload> & { sub?: number };
    if (!payload.sub || !payload.email || !payload.rol) return null;
    return { sub: payload.sub, email: payload.email, rol: payload.rol } as JwtPayload;
  } catch {
    return null;
  }
}