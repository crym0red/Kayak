Signing fix only.

The IPA was being built with a KayakTime.app bundle while the signing stage expected KayakSwiftUI.app.
This patch forces PRODUCT_NAME=KayakSwiftUI during the unsigned build, while the app's display name can remain KayakTime.

Replace only:
Scripts/build.sh
.github/workflows/build.yml
