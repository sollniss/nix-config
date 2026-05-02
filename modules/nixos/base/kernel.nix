{ ... }:
{
  # https://copy.fail/
  # https://news.ycombinator.com/item?id=47956312
  boot.blacklistedKernelModules = [
    "af_alg"
    "algif_aead"
    "algif_hash"
    "algif_rng"
    "algif_skcipher"
  ];
  boot.extraModprobeConfig = ''
    install af_alg /bin/false
    install algif_hash /bin/false
    install algif_skcipher /bin/false
    install algif_rng /bin/false
    install algif_aead /bin/false
  '';
}
