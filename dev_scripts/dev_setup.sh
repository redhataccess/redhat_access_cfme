#!/bin/sh


if [ "$1" == "" ]; then
    echo "Usage: dev_setup  <redhat_access_cfme root dir> <manageiq root dir>"
    exit 1
else
    ACCESS_DIR=$1
fi
if [ "$2" == "" ]; then
    echo "Usage: dev_setup  <redhat_access_cfme root dir> <manageiq root dir>"
    exit 1
else
    MANAGEIQ_DIR=$2
fi

mkdir -p  $MANAGEIQ_DIR/db/fixtures/miq_product_roles
mkdir -p  $MANAGEIQ_DIR/db/fixtures/miq_product_features
mkdir -p  $MANAGEIQ_DIR/db/fixtures/miq_shortcuts
mkdir -p  $MANAGEIQ_DIR/product/menubar

ln -s $ACCESS_DIR/deploy/miq_user_roles/redhat_access_user_roles.yml   $MANAGEIQ_DIR/db/fixtures/miq_product_roles/redhat_access_user_roles.yml
ln -s $ACCESS_DIR/deploy/miq_product_features/redhat_access_miq_product_features.yml    $MANAGEIQ_DIR/db/fixtures/miq_product_features/redhat_access_miq_product_features.yml

ln -s $ACCESS_DIR/deploy/menubar/redhat_access_insights_section.yml    $MANAGEIQ_DIR/product/menubar/redhat_access_insights_section.yml
ln -s $ACCESS_DIR/deploy/menubar/redhat_access_insights_item_rules.yml    $MANAGEIQ_DIR/product/menubar/redhat_access_insights_item_rules.yml
ln -s $ACCESS_DIR/deploy/menubar/redhat_access_insights_item_systems.yml    $MANAGEIQ_DIR/product/menubar/redhat_access_insights_item_systems.yml
ln -s $ACCESS_DIR/deploy/menubar/redhat_access_insights_item_overview.yml    $MANAGEIQ_DIR/product/menubar/redhat_access_insights_item_overview.yml
ln -s $ACCESS_DIR/deploy/menubar/redhat_access_insights_item_actions.yml    $MANAGEIQ_DIR/product/menubar/redhat_access_insights_item_actions.yml
ln -s $ACCESS_DIR/deploy/miq_shortcuts/redhat_access_miq_shortcuts.yml   $MANAGEIQ_DIR/db/fixtures/miq_shortcuts/redhat_access_miq_shortcuts.yml
