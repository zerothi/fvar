Name:           fdict
Version:        0.0.0
Release:        %{autorelease}
Summary:        Fortran type-free variable and type-free dictionary

License:        GPL-2.0
URL:            http://zerothi.github.io/fdict
Source:         https://github.com/zerothi/fdict/archive/refs/tags/v%{version}.tar.gz

BuildRequires:  cmake
BuildRequires:  gcc-gfortran

%description
A variable and dictionary in pure fortran for retaining any data-type and a
fast hash-table dictionary.


%prep
%autosetup -p1 -n fdict-%{version}


%build
%cmake
%cmake_build


%install
%cmake_install


%check
%ctest


%files
%license LICENSE
%doc README.md
%{_datadir}/cmake/fdict


%changelog
%autochangelog
