%define orgname drwonky
%define branch rpm_spec
%global install_path /opt
Name: flexprop
Version: 6.1.5
Release: 1%{?dist}
Summary: Flexprop GUI for Parallax Propeller development
License: MIT        
URL: https://github.com/%{orgname}/%{name}
Source0: https://github.com/%{orgname}/%{name}/archive/refs/heads/master.tar.gz
#URL: https://github.com/totalspectrum/flexprop
#Source: https://github.com/totalspectrum/flexprop.git

BuildRequires: gcc-c++ tk-devel texlive-latex pandoc libXScrnSaver-devel
Requires: bzip2-libs fontconfig freetype glib2 glibc graphite2 harfbuzz libbrotli libpng libX11 libXau libxcb libXext libXft libxml2 libXrender libXScrnSaver pcre tcl tk xz-libs zlib libgcc libstdc++

%description
FlexProp is a GUI for Parallax Propeller development. It is a cross-platform


%prep
%{__rm} -rf %{name}
%{__git} clone --recursive --depth 1 --branch %{branch} --single-branch %{url}


%build
cd %{name}
%{__make} build


%install
%{__mkdir_p} %{buildroot}%{_datadir}/%{name}
%{__mkdir_p} %{buildroot}%{_docdir}/%{name}
%{__mkdir_p} %{buildroot}%{install_path}/%{name}/bin/
%{__mkdir_p} %{buildroot}%{_bindir}
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


%changelog
* Sat Jun 03 2023 Perry Harrington <pedward@apsoft.com>
- Created spec file
