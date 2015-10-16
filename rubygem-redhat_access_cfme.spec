%{?scl:%scl_package rubygem-%{gem_name}}
%{!?scl:%global pkg_name %{name}}

%global gem_name redhat_access_cfme


%global miq_dir /var/www/miq/vmdb
%global miq_bundlerd_dir %miq_dir/bundler.d
%global miq_role_dir %miq_dir/db/fixtures/miq_product_roles
%global miq_feature_dir %miq_dir/db/fixtures/miq_product_features
%global miq_menu_dir %miq_dir/product/menubar
%global rubygem_redhat_access_cfme_dir %{gem_dir}/gems/%{gem_name}-%{version}

Name: %{?scl_prefix}rubygem-%{gem_name}
Version: 0.0.2
Release: 1%{?dist}
Summary: Summary of RedhatAccess
Group: Development/Languages
License: MIT
URL: http://labs-git.usersys.redhat.com/labs/redhat-access-proactive-cfme
Source0: %{gem_name}-%{version}.gem

Requires: %{?scl_prefix}ruby(release)
Requires: %{?scl_prefix}ruby(rubygems) 
Requires: %{?scl_prefix}ruby 
Requires: %{?scl_prefix}rubygem-redhat_access_lib >= 0.0.5
BuildRequires: %{?scl_prefix}rubygems-devel 
BuildRequires: %{?scl_prefix}ruby-devel 

Provides: %{?scl_prefix}rubygem(%{gem_name}) = %{version}
# BuildRequires: rubygem(sqlite3)
BuildArch: noarch

%description
Description of RedhatAccess.


%package doc
Summary: Documentation for %{name}
Group: Documentation
Requires: %{name} = %{version}-%{release}
BuildArch: noarch

%description doc
Documentation for %{name}.

%prep
%{?scl:scl enable %{scl} - << \EOF}
gem unpack %{SOURCE0}
%{?scl:EOF}
%setup -q -D -T -n  %{gem_name}-%{version}

%{?scl:scl enable %{scl} - << \EOF}
gem spec %{SOURCE0} -l --ruby > %{gem_name}.gemspec
%{?scl:EOF}

%build

# Create the gem as gem install only works on a gem file
%{?scl:scl enable %{scl} - << \EOF}
gem build %{gem_name}.gemspec
%{?scl:EOF}

# %%gem_install compiles any C extensions and installs the gem into ./%%gem_dir
# by default, so that we can move it into the buildroot in %%install
%{?scl:scl enable %{scl} - << \EOF}
%gem_install
%{?scl:EOF}

%install
mkdir -p %{buildroot}%{miq_dir}
mkdir -p %{buildroot}%{miq_bundlerd_dir}
mkdir -p %{buildroot}%{miq_role_dir}
mkdir -p %{buildroot}%{miq_feature_dir}
mkdir -p %{buildroot}%{miq_menu_dir}

mkdir -p %{buildroot}%{gem_dir}
cp -a .%{gem_dir}/* \
        %{buildroot}%{gem_dir}/

cat <<GEMFILE > %{buildroot}%{miq_bundlerd_dir}/%{gem_name}.rb
gem 'redhat_access_cfme'
GEMFILE

# Copy plugin enablement files
cp -pa .%{rubygem_redhat_access_cfme_dir}/deploy/miq_user_roles/* %{buildroot}%{miq_role_dir}
cp -pa .%{rubygem_redhat_access_cfme_dir}/deploy/miq_product_features/* %{buildroot}%{miq_feature_dir}
cp -pa .%{rubygem_redhat_access_cfme_dir}/deploy/menubar/* %{buildroot}%{miq_menu_dir}


# Run the test suite
%check
pushd .%{gem_instdir}

popd

%files
%defattr(-,root,root,-)
%{miq_role_dir}/redhat_access_user_roles.yml
%{miq_feature_dir}/redhat_access_miq_product_features.yml

%{miq_menu_dir}/redhat_access_insights_section.yml
%{miq_menu_dir}/redhat_access_insights_item_rules.yml
%{miq_menu_dir}/redhat_access_insights_item_systems.yml
%{miq_menu_dir}/redhat_access_insights_item_overview.yml

%{miq_bundlerd_dir}/%{gem_name}.rb

%dir %{gem_instdir}
#%{gem_instdir}
%{gem_instdir}/app
%{gem_instdir}/config
%{gem_instdir}/deploy
%{gem_instdir}/public

%{gem_libdir}
%license %{gem_instdir}/MIT-LICENSE
%exclude %{gem_cache}
%{gem_spec}

%files doc
%doc %{gem_docdir}
%{gem_instdir}/Rakefile
%doc %{gem_instdir}/README.rdoc
%{gem_instdir}/test

%changelog

* Fri Oct 2 2015 Lindani Phiri <lindani@redhat.com> - 0.0.2-1
- Switch to use of common redhataccess support lib

* Fri Sep 18 2015 Lindani Phiri - 0.0.1-2
- Fix miq application appliance location

* Fri Aug 28 2015 Lindani Phiri - 0.0.1-1
- Initial package
