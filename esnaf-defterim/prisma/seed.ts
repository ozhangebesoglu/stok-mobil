import { prisma } from "@/lib/prisma";
import bcrypt from "bcrypt";

async function main() {
  const adminEmail = "admin@kasap.com";
  const existing = await prisma.kullanici.findUnique({ where: { email: adminEmail } });
  if (!existing) {
    const saltRounds = parseInt(process.env.BCRYPT_SALT_ROUNDS || "10", 10);
    const hash = await bcrypt.hash("admin123", saltRounds);
    await prisma.kullanici.create({
      data: {
        isim: "Admin",
        email: adminEmail,
        sifre_hash: hash,
        rol: "admin",
        aktif: true,
      },
    });
    console.log("Admin kullanıcı eklendi:", adminEmail);
  } else {
    console.log("Admin zaten mevcut");
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
}).finally(async () => {
  await prisma.$disconnect();
});