# MASTER_BLUEPRINT.md — Blueprint Induk JeJu

Status: DRAFT — BELUM LENGKAP.
Dokumen ini belum boleh dianggap sebagai arsitektur final.

## Tujuan

Menjadi blueprint induk yang merangkum arsitektur, modul, alur data, keamanan, offline/sync, dan strategi pengujian JeJu.

## Acuan

- `docs/REQUIREMENTS.md`
- `DECISIONS.md`
- `AGENTS.md`

## Bagian yang harus dilengkapi

1. Arsitektur aplikasi dan pembagian layer.
2. Model data dan relasi utama.
3. Strategi autentikasi, otorisasi, dan RLS.
4. Alur pesanan, pembayaran, pemasukan, pengeluaran, transfer.
5. Aturan keuangan dan rumus laba.
6. Strategi offline/sync.
7. Strategi laporan dan ekspor.
8. Strategi pengujian per platform.
9. Strategi deployment dan biaya.

## Batas

- Belum ada keputusan arsitektur yang disetujui.
- Belum ada skema database final.
- Belum ada klaim dukungan platform.
- Keputusan terbuka di `DECISIONS.md` harus diselesaikan sebelum bagian terkait diisi final.
