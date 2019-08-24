{ stdenv, fetchFromGitHub, buildGoModule }:

buildGoModule rec {
  pname = "azure-storage-azcopy";
  version = "10.2.1";
  revision = "v10.2.1";

  src = fetchFromGitHub {
    owner = "Azure";
    repo = "azure-storage-azcopy";
    rev = revision;
    sha256 = "1vzr2vccywnph2g8cp7mivyv5cwvwcdpr1j8kf6wq14nkwqlhx7z";
  };

  modSha256 = "107ddr6rvpfwxa1z0dhsck0mnki6jh7i5862z15k1acwql8r8wmf";

  meta = with stdenv.lib; {
    maintainers = with maintainers; [ colemickens ];
    license = licenses.mit;
    description = "The new Azure Storage data transfer utility - AzCopy v10";
  };
}
