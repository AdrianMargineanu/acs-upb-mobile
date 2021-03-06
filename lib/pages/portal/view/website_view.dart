import 'package:acs_upb_mobile/authentication/model/user.dart';
import 'package:acs_upb_mobile/authentication/service/auth_provider.dart';
import 'package:acs_upb_mobile/generated/l10n.dart';
import 'package:acs_upb_mobile/pages/filter/service/filter_provider.dart';
import 'package:acs_upb_mobile/pages/filter/view/relevance_picker.dart';
import 'package:acs_upb_mobile/pages/portal/model/website.dart';
import 'package:acs_upb_mobile/pages/portal/service/website_provider.dart';
import 'package:acs_upb_mobile/resources/custom_icons.dart';
import 'package:acs_upb_mobile/resources/locale_provider.dart';
import 'package:acs_upb_mobile/resources/storage_provider.dart';
import 'package:acs_upb_mobile/resources/utils.dart';
import 'package:acs_upb_mobile/widgets/button.dart';
import 'package:acs_upb_mobile/widgets/circle_image.dart';
import 'package:acs_upb_mobile/widgets/dialog.dart';
import 'package:acs_upb_mobile/widgets/scaffold.dart';
import 'package:acs_upb_mobile/widgets/toast.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:recase/recase.dart';
import 'package:validators/validators.dart';

class WebsiteView extends StatefulWidget {
  final Website website;
  final bool updateExisting;

  // If [updateExisting] is true, this acts like an "Edit website" page starting
  // from the info in [website]. Otherwise, it acts like an "Add website" page.
  WebsiteView({Key key, this.website, this.updateExisting = false})
      : super(key: key) {
    if (this.updateExisting == true && this.website == null) {
      throw ArgumentError(
          'WebsiteView: website cannot be null if updateExisting is true');
    }
  }

  @override
  _WebsiteViewState createState() => _WebsiteViewState();
}

class _WebsiteViewState extends State<WebsiteView> {
  final _formKey = GlobalKey<FormState>();

  WebsiteCategory _selectedCategory;
  TextEditingController _labelController;
  TextEditingController _linkController;
  TextEditingController _descriptionRoController;
  TextEditingController _descriptionEnController;
  RelevanceController _relevanceController = RelevanceController();

  User _user;

  _fetchUser() async {
    AuthProvider authProvider = Provider.of(context, listen: false);
    _user = await authProvider.currentUser;
    setState(() {});
  }

  @override
  initState() {
    super.initState();
    _fetchUser();

    _selectedCategory = widget.website?.category ?? WebsiteCategory.learning;
    _labelController = TextEditingController(text: widget.website?.label ?? '');
    _linkController = TextEditingController(text: widget.website?.link ?? '');

    Map<String, String> description = {'en': '', 'ro': ''};
    if (widget.website != null) {
      description['en'] = widget.website.infoByLocale.containsKey('en')
          ? widget.website.infoByLocale['en']
          : '';
      description['ro'] = widget.website.infoByLocale.containsKey('ro')
          ? widget.website.infoByLocale['ro']
          : '';
    }
    _descriptionRoController = TextEditingController(text: description['ro']);
    _descriptionEnController = TextEditingController(text: description['en']);
  }

  String _buildId() {
    if (widget.updateExisting) return widget.website.id;
    String label = (_labelController.text ?? '') == ''
        ? Website.labelFromLink(_linkController.text)
        : _labelController.text;
    // Sanitize label to obtain document ID
    return ReCase(label.replaceAll(RegExp('[^A-ZĂÂȘȚa-zăâșț0-9 ]'), ''))
        .snakeCase;
  }

  Website _buildWebsite() {
    return Website(
      id: _buildId(),
      ownerUid: widget.updateExisting ? widget.website.ownerUid : _user?.uid,
      isPrivate: _relevanceController.private ?? true,
      editedBy: (widget.website?.editedBy ?? []) + [_user?.uid],
      label: _labelController.text,
      link: _linkController.text,
      category: _selectedCategory,
      iconPath: widget.website?.iconPath ?? 'icons/websites/globe.png',
      infoByLocale: {
        'ro': _descriptionRoController.text,
        'en': _descriptionEnController.text
      },
      relevance: _relevanceController.customRelevance,
      degree: _relevanceController.degree ?? widget.website?.degree,
    );
  }

  Widget _preview() {
    Website website = _buildWebsite();

    return Padding(
      padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 8.0),
      child: Card(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: <Widget>[
                  Icon(Icons.remove_red_eye,
                      color: CustomIcons.formIconColor(Theme.of(context))),
                  SizedBox(width: 12.0),
                  AutoSizeText(
                    S.of(context).labelPreview + ':',
                    style: Theme.of(context).textTheme.subtitle1,
                  ),
                  SizedBox(width: 12.0),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Expanded(
                          child: FutureBuilder<ImageProvider<dynamic>>(
                            future: Provider.of<StorageProvider>(context,
                                    listen: false)
                                .imageFromPath(website.iconPath),
                            builder: (context, snapshot) {
                              ImageProvider<dynamic> image =
                                  AssetImage('assets/icons/websites/globe.png');
                              if (snapshot.hasData) {
                                image = snapshot.data;
                              }
                              return CircleImage(
                                label: website.label,
                                onTap: () => Utils.launchURL(website.link,
                                    context: context),
                                image: image,
                                tooltip: website
                                    .infoByLocale[LocaleProvider.localeString],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
              child: AutoSizeText(
                S.of(context).messageWebsitePreview,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).hintColor),
              ),
            )
          ],
        ),
      ),
    );
  }

  AppDialog _deletionConfirmationDialog(BuildContext context) => AppDialog(
        icon: Icon(Icons.delete),
        title: S.of(context).actionDeleteWebsite,
        message: S.of(context).messageDeleteWebsite,
        info: widget.website.isPrivate
            ? null
            : S.of(context).messageThisCouldAffectOtherStudents,
        actions: [
          AppButton(
            text: S.of(context).actionDeleteWebsite,
            width: 130,
            onTap: () async {
              Navigator.pop(context); // Pop dialog window

              WebsiteProvider websiteProvider =
                  Provider.of<WebsiteProvider>(context, listen: false);
              bool res = await websiteProvider.deleteWebsite(widget.website,
                  context: context);
              if (res) {
                Navigator.pop(context); // Pop editing page
                AppToast.show(S.of(context).messageWebsiteDeleted);
              }
            },
          )
        ],
      );

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: widget.updateExisting
          ? S.of(context).actionEditWebsite
          : S.of(context).actionAddWebsite,
      actions: [
            AppScaffoldAction(
              text: S.of(context).buttonSave,
              onPressed: () async {
                if (_formKey.currentState.validate()) {
                  WebsiteProvider websiteProvider =
                      Provider.of<WebsiteProvider>(context, listen: false);

                  bool res = false;
                  if (_relevanceController.private ||
                      _relevanceController.anyone) {
                    res = await websiteProvider.addWebsite(
                      _buildWebsite(),
                      updateExisting: widget.updateExisting,
                      context: context,
                    );
                  } else {
                    res = await websiteProvider.addWebsite(
                      _buildWebsite(),
                      updateExisting: widget.updateExisting,
                      context: context,
                    );
                  }
                  if (res) {
                    AppToast.show(widget.updateExisting
                        ? S.of(context).messageWebsiteEdited
                        : S.of(context).messageWebsiteAdded);
                    Navigator.of(context).pop();
                  }
                }
              },
            ),
          ] +
          (widget.updateExisting
              ? [
                  AppScaffoldAction(
                    icon: Icons.more_vert,
                    items: {
                      S.of(context).actionDeleteWebsite: () => showDialog(
                          context: context,
                          child: _deletionConfirmationDialog(context))
                    },
                    onPressed: () => showDialog(
                        context: context,
                        child: _deletionConfirmationDialog(context)),
                  )
                ]
              : <AppScaffoldAction>[]),
      body: SafeArea(
        child: ListView(
          children: <Widget>[
            _preview(),
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: <Widget>[
                    TextFormField(
                      controller: _labelController,
                      decoration: InputDecoration(
                        labelText: S.of(context).labelName,
                        hintText: S.of(context).hintWebsiteLabel,
                        prefixIcon: Icon(Icons.label),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    DropdownButtonFormField<WebsiteCategory>(
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: S.of(context).labelCategory,
                        prefixIcon: Icon(Icons.category),
                      ),
                      value: _selectedCategory,
                      items: WebsiteCategory.values
                          .map(
                            (category) => DropdownMenuItem<WebsiteCategory>(
                              value: category,
                              child: Text(category.toLocalizedString(context)),
                            ),
                          )
                          .toList(),
                      onChanged: (selection) =>
                          setState(() => _selectedCategory = selection),
                    ),
                    TextFormField(
                      controller: _linkController,
                      decoration: InputDecoration(
                        labelText: S.of(context).labelLink + ' *',
                        hintText: S.of(context).hintWebsiteLink,
                        prefixIcon: Icon(Icons.public),
                      ),
                      validator: (value) {
                        if (!isURL(value, requireProtocol: true)) {
                          return S.of(context).warningInvalidURL;
                        }
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                    RelevancePicker(
                      filterProvider: Provider.of<FilterProvider>(context),
                      defaultPrivate: widget.website?.isPrivate ?? true,
                      defaultRelevance: widget.website?.relevance,
                      controller: _relevanceController,
                    ),
                    TextFormField(
                      controller: _descriptionRoController,
                      decoration: InputDecoration(
                          labelText: S.of(context).labelDescription +
                              ' (' +
                              S
                                  .of(context)
                                  .settingsItemLanguageRomanian
                                  .toLowerCase() +
                              ')',
                          hintText: 'Cel mai popular motor de căutare.',
                          prefixIcon: Icon(Icons.info)),
                      onChanged: (_) => setState(() {}),
                      minLines: 1,
                      maxLines: 5,
                    ),
                    TextFormField(
                      controller: _descriptionEnController,
                      decoration: InputDecoration(
                          labelText: S.of(context).labelDescription +
                              ' (' +
                              S
                                  .of(context)
                                  .settingsItemLanguageEnglish
                                  .toLowerCase() +
                              ')',
                          hintText: 'The most popular search engine.',
                          prefixIcon: Icon(Icons.info)),
                      onChanged: (_) => setState(() {}),
                      minLines: 1,
                      maxLines: 5,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
