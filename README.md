# Aplikasi pemantau data rekapitulasi Pilpres 2024

## Introduction
Aplikasi ini digunakan untuk memantau rekapitulasi perhitungan suara pada seluruh TPS di Indonesia, dan TPS RI di Luar Negeri.
Masifnya data yang tidak sesuai dengan C1 Plano pada masing-masing TPS saat ditampilkan pada website KPU mendorong untuk dibuatnya sistem pemantau ini.

## Specification
Aplikasi ini menggunakan Ruby on Rails, dengan database MongoDB. Data didapatkan menggunakan metode Crawl dari API KPU.
Saat ini visualisasi (Web interface) belum dibuat. Cek data menggunakan `rails console` dengan memanggil method `.check` dari class `Fraud::PollingStationChecker`.

Spesifikasi Aplikasi
- Ruby 3.2.2
- Rails 7.1.3
- Sidekiq 7.2.2 (Job Processor)

Aplikasi ini membutuhkan penunjang lainnya, seperti:
- MongoDB 7.0.5
- Redis Server 7.2.4

## Instalation
Install Ruby terlebih dahulu, sangat disarankan menggunakan `rbenv`. Silahkan caritahu instalasi rbenv yang sesuai dengan OS kalian.
Setelah ruby terinstall, install `foreman` dengan perintah `gem install foreman`. Foreman digunakan untuk menjalankan Server, dan juga menjalankan Job Processor (Sidekiq)

Jika proses instalasi Ruby, Rails, Sidekiq, dan DB telah selesai, langkah selanjutnya adalan mengimport data Presiden dan seluruh TPS pada link berikut: [Rekapitulasi TPS 2024 (Pilpres)](https://drive.google.com/drive/folders/1z4vK-Y_Mj-SQN2BzeAdcbVDU_hkTZj--?usp=sharing). Pastikan data yang di-impor ke MongoDB menjadi collection. Format collection seperti ini: `pilpres_2024.<collection_name>_development (tanpa tanda <>)`, jika hasil import tidak sesuai, silahkan rename collection tersebut.

Setelah semuanya terpenuhi, buka 3 terminal window CMD/Bash, lalu ketik perintah berikut:
- Window pertama: `foreman start`
- Window kedua: `foreman start -f Procfile.sidekiq`
- Window ketiga: `rails console`

Diasumsikan kalian baru menyelesaikan instalasi ini pertama kali. Langkah selanjutnya untuk mulai menganalisis data rekapitulasi yaitu dengan meng-crawl semua data dari API KPU. Pada window ketiga, setelah login ke Rails Console, ketik perintah: `PollingStation.synchronize_recapitulation`. Perintah ini akan mentrigger Sidekiq Background Job. Pastikan internet terhubung dan perangkat dalam keadaan stabil. Download data ini akan berlangsung lumayan lama.

## Usecase
Setelah seluruh data rekapitulasi selesai didownload (pastikan jumlah document pada collection tersebut sesuai dengan TPS terdaftar: **823236 TPS**), masuk ke Rails Console dan mulai analisis menggunakan Query Interface dari method `Fraud::PollingStationChecker.check`.

Polling Station Checker menggunakan 2 metode:
- Max Voters
- Valid Voters

Metode `max_voters` digunakan untuk mencari seluruh TPS dengan perolehan suara masing-masing presiden lebih dari 300 (berdasarkan peraturan KPU tahun 2022, maksimum DPT setiap TPS adalah 300). Namun, metode ini juga masih belum menunjukkan hasil yang maksimal, karena jumlah DPT pada TPS di luar negeri bisa lebih dari 400. Solusi kedua menggunakan `valid_voters`. Metode ini membandingkan total suara sah yang tercatat, dengan suara masing-masing presiden. Namun pada kenyataannya, data dari KPU masih sangat kotor, seperti adanya data terinput berupa suara sah setiap presiden, namun tidak disertai data administrasi yang menampilkan suara sah keseluruhan, suara tidak sah, DPT, DPTk dsb.

Solusi untuk memfillter data ini menggunakan Query tambahan.

Contoh penggunaan:
```ruby
# Mencari TPS di Kota Bogor yang perolehan suara masing-masing presiden lebih besar dari suara sah, dengan sample 80K TPS,
# hanya untuk capres Prabowo, dimana data suara sah pada kolom administrasi bukan 0.
bogor_poll_station_ids = PollingStation.in(
  village_id: Village.in(
    district_id: District.in(
      state_id: State.search({ nama: 'bogor' }, [:nama]).first.id
    ).pluck(:id)
  ).pluck(:id)
).pluck(:id)

Fraud::PollingStationChecker.check(
  comparator: :valid_voters,
  sample: 80_000,
  skip_ids: President.search({ nama: ['anies', 'ganjar'] }, [:nama]).pluck(:id),
  query: -> { where(:polling_station_id.in => bogor_poll_station_ids).not('administrasi.suara_sah' => "0") }
)
```

Perlu diingat, Query tambahan dengan metode `valid_voters` akan mempersempit hasil pencarian, dan kadang menimbulkan ambiguitas (example: Perolehan suara paslon 02 => 500, dengan mengecualikan suara sah 0 pada kolom administrasi. Jika terdapat data TPS dari paslon 02 yang tidak valid [namun administrasi suara sahnya 0], maka TPS ini tidak dianggap sebagai "tidak valid"). Analisis mendalam dari hasil query masih perlu dilakukan kembali, untuk mendapatkan hasil rekapitulasi data yang benar-benar optimal. Mungkin penggabungan Max Voters, dengan Valid Voters.
