%define buildid @BUILDID@

%global debug_package %{nil}

Name:      ec2-agent
Summary:   Synchronizes login credentials from EC2 Instance Metadata Service
Version:   0.1.0
Release:   ROCKIT1.rc2%{?buildid}%{?byte_code_mark}%{?dist}
License:   GPLv3
Vendor:    ROCKITTEST
URL:       https://github.com/C2Devel/ec2-agent
Source0:   ec2-agent-%{version}.tar.gz

BuildArch: x86_64

BuildRequires: golang

Requires: systemd
Requires: sudo
Requires: shadow-utils

%description
Synchronizes login credentials from the Instance Metadata Service (IMDS).

%prep
%setup -q -n ec2-agent-%{version}

%build
export CGO_ENABLED=0
go build -o ec2-agent ./cmd/ec2-agent

%install
install -Dpm755 ec2-agent %{buildroot}%{_bindir}/ec2-agent
install -Dpm644 systemd/ec2-agent.service %{buildroot}%{_unitdir}/ec2-agent.service
install -Dpm644 systemd/ec2-agent.timer %{buildroot}%{_unitdir}/ec2-agent.timer

%clean
rm -rf %{buildroot}

%files
%attr(0755, root, root) %{_bindir}/ec2-agent
%{_unitdir}/ec2-agent.service
%{_unitdir}/ec2-agent.timer

%post
systemctl --quiet daemon-reload
systemctl enable --now ec2-agent.timer

%preun
systemctl --quiet stop ec2-agent.timer ec2-agent.service 2>/dev/null || true
systemctl --quiet disable ec2-agent.timer 2>/dev/null || true

%postun
systemctl --quiet daemon-reload

%changelog
* Wed Oct 07 2026 Automation <devel@k2.cloud> - 0.1.0-ROCKIT1
- Initial package