{ cmake, fetchurl, python, stdenv }:

stdenv.mkDerivation rec {

  pname = "sundials";
  version = "3.2.1";

  src = fetchurl {
    url = "https://computation.llnl.gov/projects/${pname}/download/${pname}-${version}.tar.gz";
    sha256 = "0238r1qnwqz13wcjzfsbcfi8rfnlxcjjmxq2vpf2qf5jgablvna7";
  };


  cmakeFlags = [
    "-DEXAMPLES_INSTALL_PATH=${placeholder "out"}/share/examples"
  ];

  nativeBuildInputs = [ cmake ];
  buildInputs = [ python ];

  meta = with stdenv.lib; {
    description = "Suite of nonlinear differential/algebraic equation solvers";
    homepage    = https://computation.llnl.gov/projects/sundials;
    platforms   = platforms.all;
    maintainers = [ maintainers.idontgetoutmuch ];
    license     = licenses.bsd3;
  };

}
