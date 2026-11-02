# CURRENT_STATE.md — Status Proyek JeJu

Terakhir diperbarui: 2026-11-02

## Fase saat ini

Fase 7 — Tim & Undangan (selesai). Siap masuk Fase 8 (Offline/Sync).

## Sudah selesai

- Fase 1–6: skema, auth, UI, pelanggan, pesanan, pembayaran, keuangan, pengaturan, laporan, ekspor CSV+XLSX.
- Fase 7 — Tim & Undangan:
  - Migration 0700: tabel `business_invitations` + RLS + RPC `list_business_members`.
  - Migration 0701: RPC `create_invitation` + `revoke_invitation`.
  - Migration 0702: RPC `accept_invitation`.
  - Multi-business: `CurrentBusinessNotifier` (AsyncNotifier) + `BusinessSelectorButton` di Dashboard AppBar.
  - Model: `BusinessMemberInfo`, `Invitation`, `CreatedInvitation`.
  - Service: `MembersService` (list, listPending, create, revoke, accept).
  - Providers: `membersProvider`, `pendingInvitationsProvider`, `membersControllerProvider`.
  - UI: `MembersScreen` (list + invite + revoke), `InviteDialog` (link generation + copy), `AcceptInviteScreen` (token flow).
  - Route `/accept-invite` (public) + `/app/more/members` (dalam shell).
  - pgTAP: `invitations_rpc.sql` (18 test).
  - Widget test: members (5) + accept-invite (3).

**Total: 55 Flutter tests + 163 pgTAP tests.**

## Keputusan

- D-01..D-04, D-07: APPROVED.
- A-01..A-08, U-01..U-07, C-01..C-08: APPROVED.
- Q1, Q5-A, Q3-A, Q4-A, Q8-A, E-01-A: APPROVED.
- F5-01-A s/d F5-04-A: APPROVED.
- F6-01 (revised B2), F6-02-A, F6-03-A, F6-04-A: APPROVED.
- D-05: APPROVED (revised) — CSV + XLSX, PDF ditunda.
- F7-01 (manual link), F7-02, F7-03, F7-04, Q2: APPROVED.

## Pertanyaan terbuka (Fase 8)

- F8-01 — Pilihan database lokal (default: `drift` untuk Dart-native, atau `sqflite` dengan conditional export).
- F8-02 — Teknologi enkripsi lokal (default: `sqlcipher` via `sqflite_sqlcipher`).
- F8-03 — Algoritma resolusi konflik (default: server-wins untuk master data, custom untuk transaksi).
- F8-04 — Cakupan offline (default: read semua, write untuk pelanggan + pesanan + pembayaran + transaksi + transfer).
- F8-05 — Idempotency key di semua mutasi offline (wajib).

## Technical debt

- Controller `TextEditingController` di dialog one-shot tidak di-dispose (leak minor).
- `FakeOrdersService` tidak merecompute `paid_amount`.
- `PaymentsScreen` masih placeholder.
- `ExportService.paymentsCsv` belum punya tombol UI.
- Web download via `dart:html` (deprecated; migrasi `package:web` Fase 8+).
- Mobile file save native (`path_provider`) ditunda.
- Custom columns (req 5.8) ditunda.
- Pagination/server-side search ditunda.
- Ganti bisnis dari screen selain Dashboard belum ada (hanya dari Dashboard AppBar).
- Persistent selection multi-business (shared_preferences) ditunda Fase 8.

## Batas yang diakui

- Supabase lokal (Docker), belum remote.
- Build iOS & native Windows belum diverifikasi.
- Rumus laba operasional belum final (D-02).

## Langkah berikutnya

1. Putuskan F8-01..F8-05.
2. Langkah 15: Fase 8 — Offline & Sync.
