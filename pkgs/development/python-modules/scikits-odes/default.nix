{ stdenv
, lib
, buildPythonPackage
, fetchPypi
, cython
, enum34
, gfortran
, isPy3k
, numpy
, pytest
, python
, scipy
, sundials_3
}:

buildPythonPackage rec {
  pname = "scikits.odes";
  version = "2.4.0";

  src = fetchPypi {
    inherit pname version;
    sha256 = "103xg1k1gps8sp7fmbqa570x3d7kscg6bzw1innl2jil1d416glf";
  };

  nativeBuildInputs = [
    gfortran
    cython
  ];

  propagatedBuildInputs = [
    numpy
    sundials_3
    scipy
  ] ++ lib.optionals (!isPy3k) [ enum34 ];

  # https://grokbase.com/t/gg/cython-users/13987sentw/cython-inline-causing-errors-on-macos-with-clang#20130908e6otbth2q2uhx5hqe7ujqsrxe4
  postPatch = lib.optionalString stdenv.cc.isClang ''
    sed -i scikits/odes/sundials/common_defs.pxd -e "s|inline ||"
  '';

  doCheck = true;
  checkInputs = [ pytest ];

  checkPhase = ''
    cd $out/${python.sitePackages}/scikits/odes/tests

    # disable lapack tests, as we build numpy and scipy without it
    sed -i test_odeint.py -e "s|^TEST_LAPACK =.*$|TEST_LAPACK = False|"

    pytest
  '';

  meta = with stdenv.lib; {
    description = "A scikit offering extra ode/dae solvers, as an extension to what is available in scipy";
    homepage = https://github.com/bmcage/odes;
    license = licenses.bsd3;
    maintainers = with maintainers; [ flokli ];
  };
}
