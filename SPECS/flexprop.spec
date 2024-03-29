%define orgname totalspectrum
%define branch master
%global install_path /opt
Name: flexprop
Version: 6.1.5
Release: 1%{?dist}
Summary: Flexprop GUI for Parallax Propeller development
License: MIT        
URL: https://github.com/%{orgname}/%{name}
Source0: https://github.com/%{orgname}/%{name}/archive/%{branch}/%{name}.tar.gz
Source1: https://github.com/totalspectrum/PropLoader/archive/master/PropLoader.tar.gz
Source2: https://github.com/totalspectrum/spin2cpp/archive/master/spin2cpp.tar.gz
Source3: https://github.com/totalspectrum/loadp2/archive/master/loadp2.tar.gz

BuildRequires: gcc-c++ tk-devel texlive-latex pandoc libXScrnSaver-devel
Requires: bzip2-libs fontconfig freetype glib2 glibc graphite2 harfbuzz libbrotli libpng libX11 libXau libxcb libXext libXft libxml2 libXrender libXScrnSaver pcre tcl tk xz-libs zlib libgcc libstdc++

%description
FlexProp is a GUI for Parallax Propeller development.

# TODO: It would be ideal if we could use spectool with a tarball, but with recursive
# submodules, it doesn't work
%prep
%{__rm} -rf %{_builddir}/%{name}
%{__mkdir_p} %{_builddir}/%{name}
cd %{_builddir}/%{name}
%{__tar} --strip-components=1 -xzf %{_sourcedir}/%{name}.tar.gz
cd %{_builddir}/%{name}/PropLoader
%{__tar} --strip-components=1 -xzf %{_sourcedir}/PropLoader.tar.gz
cd %{_builddir}/%{name}/spin2cpp
%{__tar} --strip-components=1 -xzf %{_sourcedir}/spin2cpp.tar.gz
cd %{_builddir}/%{name}/loadp2
%{__tar} --strip-components=1 -xzf %{_sourcedir}/loadp2.tar.gz

# We can't use %{make_build} because this won't compile with parallel Makes running
%build
cd %{_builddir}/%{name}/spin2cpp
%{make_build}
cd %{_builddir}/%{name}
%{__make} build


%install
%{__mkdir_p} %{buildroot}%{_datadir}/%{name}
%{__mkdir_p} %{buildroot}%{_docdir}/%{name}
%{__mkdir_p} %{buildroot}%{_sysconfdir}/profile.d/
%{__mkdir_p} %{buildroot}%{install_path}/%{name}/bin/
%{__mkdir_p} %{buildroot}%{_bindir}
%{__install} -p -m 0644 %{_builddir}/%{name}/SPECS/flexprop.sh %{buildroot}%{_sysconfdir}/profile.d/
%{__install} -p -m 0644 %{_builddir}/%{name}/License.txt %{buildroot}%{_docdir}/%{name}
%{__install} -p -m 0644 %{_builddir}/%{name}/README.md %{buildroot}%{_docdir}/%{name}
%{__cp} -r %{_builddir}/%{name}/doc %{buildroot}%{_docdir}/%{name}/
%{__install} -p -m 0755 %{_builddir}/%{name}/%{name}.bin %{buildroot}%{install_path}/%{name}/%{name}
%{__install} -p -m 0755 %{_builddir}/%{name}/bin/* %{buildroot}%{install_path}/%{name}/bin/
%{__cp} -r %{_builddir}/%{name}/%{name}/include %{buildroot}%{install_path}/%{name}/
%{__cp} -r %{_builddir}/%{name}/%{name}/board %{buildroot}%{install_path}/%{name}/
%{__cp} -r %{_builddir}/%{name}/%{name}/samples %{buildroot}%{install_path}/%{name}/
%{__cp} -r %{_builddir}/%{name}/%{name}/src %{buildroot}%{install_path}/%{name}/
%{__cp} -r %{_builddir}/%{name}/tcl_library %{buildroot}%{install_path}/%{name}/


%files
%license %{_docdir}/%{name}/License.txt
%doc %{_docdir}/%{name}/doc/
%{_docdir}/%{name}/README.md
%{_datadir}/%{name}/
%{install_path}/%{name}/
%{_sysconfdir}/profile.d/flexprop.sh


%changelog
* Sat Jun 03 2023 Perry Harrington <pedward@apsoft.com>
- Created spec file
