#!/bin/bash
while IFS= read -r domain; do
  # Pastikan baris tidak kosong dan bukan komentar
  if [[ -n "$domain" && ! "$domain" =~ ^\s*# ]]; then
    echo "0.0.0.0 $domain" >> hosts.raw
  fi
done < custom.list

