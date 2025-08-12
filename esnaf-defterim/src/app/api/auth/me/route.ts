import { NextRequest, NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { verifyToken } from "@/lib/auth";

function withCors(res: NextResponse) {
  res.headers.set("Access-Control-Allow-Origin", "*");
  res.headers.set("Access-Control-Allow-Methods", "GET,POST,OPTIONS");
  res.headers.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
  return res;
}

export async function OPTIONS() {
  return withCors(new NextResponse(null, { status: 204 }));
}

export async function GET(req: NextRequest) {
  const auth = req.headers.get("authorization");
  if (!auth?.startsWith("Bearer ")) {
    return withCors(NextResponse.json({ error: "Yetkisiz" }, { status: 401 }));
  }
  const token = auth.slice("Bearer ".length);
  const payload = verifyToken(token);
  if (!payload) {
    return withCors(NextResponse.json({ error: "Geçersiz token" }, { status: 401 }));
  }
  const user = await prisma.kullanici.findUnique({ where: { kullanici_id: payload.sub } });
  if (!user) {
    return withCors(NextResponse.json({ error: "Kullanıcı yok" }, { status: 404 }));
  }
  return withCors(NextResponse.json({
    id: user.kullanici_id,
    isim: user.isim,
    email: user.email,
    rol: user.rol,
  }));
}