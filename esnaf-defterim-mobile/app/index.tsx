import { useEffect, useState } from 'react';
import { SafeAreaView, Text, View, Pressable } from 'react-native';
import { runMigrations, db } from '@/utils/db';

export default function Home() {
  const [ready, setReady] = useState(false);
  const [urunSayisi, setUrunSayisi] = useState<number | null>(null);

  useEffect(() => {
    try {
      runMigrations();
      db.execAsync('SELECT COUNT(*) as cnt FROM stoklar').then((rows: any) => {
        const count = Array.isArray(rows) && rows[0]?.cnt ? rows[0].cnt : 0;
        setUrunSayisi(count);
        setReady(true);
      }).catch(() => setReady(true));
    } catch {
      setReady(true);
    }
  }, []);

  if (!ready) {
    return (
      <SafeAreaView style={{ flex: 1, alignItems: 'center', justifyContent: 'center' }}>
        <Text>Yükleniyor...</Text>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={{ flex: 1 }}>
      <View style={{ padding: 16 }}>
        <Text style={{ fontSize: 24, fontWeight: '700' }}>Esnaf Defterim (Lokal)</Text>
        <Text style={{ marginTop: 8 }}>Stok ürün sayısı: {urunSayisi ?? '-'}</Text>

        <View style={{ flexDirection: 'row', marginTop: 16, gap: 12 }}>
          <Pressable style={{ backgroundColor: '#111827', padding: 12, borderRadius: 8 }}>
            <Text style={{ color: 'white', fontWeight: '600' }}>Stok Ekle</Text>
          </Pressable>
          <Pressable style={{ backgroundColor: '#6B7280', padding: 12, borderRadius: 8 }}>
            <Text style={{ color: 'white', fontWeight: '600' }}>Ürünler</Text>
          </Pressable>
        </View>
      </View>
    </SafeAreaView>
  );
}