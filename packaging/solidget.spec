# Solidget as an RPM, built on Copr: https://copr.fedorainfracloud.org/coprs/livlign/solidget/
# The version must match package/metadata.json (tests/run.sh checks).

%global plugin_id io.github.solidget

Name:           solidget
Version:        0.6.0
Release:        1%{?dist}
Summary:        Live stats, PC specs and your day in one Plasma desktop widget

# Widget: GPL-2.0-or-later. Bundled Silkscreen font: OFL-1.1.
License:        GPL-2.0-or-later AND OFL-1.1
URL:            https://github.com/livlign/solidget
Source0:        %{url}/archive/v%{version}/%{name}-%{version}.tar.gz

BuildArch:      noarch
BuildRequires:  python3

Requires:       plasma-workspace >= 6.0
Requires:       libplasma
Requires:       plasma5support
Requires:       kf6-kirigami
Requires:       kf6-ksvg
Requires:       libksysguard
Requires:       ksystemstats
Requires:       python3

%description
Solidget is a desktop widget for KDE Plasma 6: live CPU, GPU, memory,
network and disk stats, your PC's specs, a clock with weather, and more,
in one board that matches your Plasma desktop.

After installing, right-click the desktop, choose Add Widgets and search
for Solidget.

%prep
%autosetup -n %{name}-%{version}

%build
# Nothing to build: QML, JavaScript and one Python helper.

%install
install -d %{buildroot}%{_datadir}/plasma/plasmoids/%{plugin_id}
cp -a package/. %{buildroot}%{_datadir}/plasma/plasmoids/%{plugin_id}/
find %{buildroot}%{_datadir}/plasma/plasmoids/%{plugin_id} \
    \( -name __pycache__ -o -name '*.pyc' \) -prune -exec rm -rf {} +
# The helper runs as "python3 -I specs.py", so it needs no exec bit.
chmod 0644 %{buildroot}%{_datadir}/plasma/plasmoids/%{plugin_id}/contents/code/specs.py

%check
python3 -c 'import json, sys; v = json.load(open("package/metadata.json"))["KPlugin"]["Version"]; sys.exit(v != "%{version}")'

%files
%license LICENSE package/contents/fonts/OFL.txt
%doc README.md CHANGELOG.md
%{_datadir}/plasma/plasmoids/%{plugin_id}/

%changelog
* Thu Oct 15 2026 Solidget contributors - 0.6.0-1
- First RPM release; see CHANGELOG.md for what's in 0.6.0
