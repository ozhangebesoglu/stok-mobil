import { NextRequest, NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { signToken, verifyPassword } from "@/lib/auth";

function withCors(res: NextResponse) {
  res.headers.set("Access-Control-Allow-Origin", "*");
  res.headers.set("Access-Control-Allow-Methods", "GET,POST,OPTIONS");
  res.headers.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
  return res;
}

export async function OPTIONS() {
  return withCors(new NextResponse(null, { status: 204 }));
}

export async function POST(req: NextRequest) {
  try {
    const { email, password } = await req.json();
    if (!email || !password) {
      return withCors(NextResponse.json({ error: "Email ve şifre gerekli" }, { status: 400 }));
    }

    const user = await prisma.kullanici.findUnique({ where: { email } });
    if (!user || !user.aktif) {
      return withCors(NextResponse.json({ error: "Kullanıcı bulunamadı veya pasif" }, { status: 401 }));
    }

    const ok = await verifyPassword(password, user.sifre_hash);
    if (!ok) {
      return withCors(NextResponse.json({ error: "Hatalı şifre" }, { status: 401 }));
    }

    const token = signToken({ sub: user.kullanici_id, email: user.email, rol: user.rol });

    return withCors(NextResponse.json({
      token,
      user: {
        id: user.kullanici_id,
        isim: user.isim,
        email: user.email,
        rol: user.rol,
      }
    }));
  } catch (e) {
    return withCors(NextResponse.json({ error: "Sunucu hatası" }, { status: 500 }));
  }
}