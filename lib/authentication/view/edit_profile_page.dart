import 'package:acs_upb_mobile/authentication/model/user.dart';
import 'package:acs_upb_mobile/authentication/service/auth_provider.dart';
import 'package:acs_upb_mobile/authentication/view/dropdown_tree.dart';
import 'package:acs_upb_mobile/generated/l10n.dart';
import 'package:acs_upb_mobile/resources/utils.dart';
import 'package:acs_upb_mobile/widgets/button.dart';
import 'package:acs_upb_mobile/widgets/dialog.dart';
import 'package:acs_upb_mobile/widgets/scaffold.dart';
import 'package:acs_upb_mobile/widgets/toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:preferences/preference_title.dart';
import 'package:provider/provider.dart';

class EditProfilePage extends StatefulWidget {
  EditProfilePage({Key key}) : super(key: key);

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final dropdownController = DropdownTreeController();

  final formKey = GlobalKey<FormState>();

  AppDialog _deletionConfirmationDialog(BuildContext context) {
    final passwordController = TextEditingController();
    return AppDialog(
      icon: Icon(Icons.warning, color: Colors.red),
      title: S.of(context).actionDeleteAccount,
      message: S.of(context).messageDeleteAccount +
          ' ' +
          S.of(context).messageCannotBeUndone,
      content: [
        TextFormField(
          decoration: InputDecoration(
            labelText: S.of(context).labelConfirmPassword,
            hintText: S.of(context).hintPassword,
          ),
          obscureText: true,
          controller: passwordController,
        )
      ],
      actions: [
        AppButton(
          key: ValueKey('delete_account_button'),
          text: S.of(context).actionDeleteAccount.toUpperCase(),
          color: Colors.red,
          width: 130,
          onTap: () async {
            AuthProvider authProvider =
                Provider.of<AuthProvider>(context, listen: false);
            if (await authProvider.verifyPassword(
                password: passwordController.text, context: context)) {
              if (await authProvider.delete(context: context)) {
                Utils.signOut(context);
              }
            }
          },
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    AuthProvider authProvider = Provider.of<AuthProvider>(context);
    return AppScaffold(
      title: S.of(context).actionEditProfile,
      actions: [
        AppScaffoldAction(
            text: S.of(context).buttonSave,
            onPressed: () async {
              Map<String, dynamic> info = {
                S.of(context).labelFirstName: firstNameController.text,
                S.of(context).labelLastName: lastNameController.text,
              };
              if (dropdownController.path != null) {
                info['class'] = dropdownController.path;
              }

              if (formKey.currentState.validate()) {
                bool result = await authProvider.updateProfile(
                  info: info,
                  context: context,
                );

                if (result) {
                  AppToast.show(S.of(context).messageEditProfileSuccess);
                  Navigator.pop(context);
                }
              }
            }),
        AppScaffoldAction(
          icon: Icons.more_vert,
          items: {
            S.of(context).actionDeleteAccount: () => showDialog(
                context: context, child: _deletionConfirmationDialog(context))
          },
        )
      ],
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: FutureBuilder(
            future: authProvider.currentUser,
            builder: (BuildContext context, AsyncSnapshot<User> snap) {
              List<String> path;
              if (snap.hasData) {
                User user = snap.data;
                lastNameController.text = user.lastName;
                firstNameController.text = user.firstName;
                path = user.classes;
                return Container(
                  child: ListView(children: [
                    PreferenceTitle(
                      S.of(context).labelPersonalInformation,
                      leftPadding: 0,
                    ),
                    Form(
                      key: formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.person),
                              labelText: S.of(context).labelFirstName,
                              hintText: S.of(context).hintFirstName,
                            ),
                            controller: firstNameController,
                            validator: (value) {
                              if (value.isEmpty || value == null) {
                                return S.of(context).errorMissingFirstName;
                              }
                              return null;
                            },
                          ),
                          TextFormField(
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.person),
                              labelText: S.of(context).labelLastName,
                              hintText: S.of(context).hintLastName,
                            ),
                            controller: lastNameController,
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return S.of(context).errorMissingLastName;
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    PreferenceTitle(
                      S.of(context).labelClass,
                      leftPadding: 0,
                    ),
                    DropdownTree(
                      initialPath: path,
                      controller: dropdownController,
                      leftPadding: 10.0,
                      textStyle: Theme.of(context)
                          .textTheme
                          .caption
                          .apply(color: Theme.of(context).hintColor),
                    )
                  ]),
                );
              } else {
                return Center(child: CircularProgressIndicator());
              }
            }),
      ),
    );
  }
}
