import 'dart:async';
import 'package:atsign_atmosphere_app/services/navigation_service.dart';
import 'package:flutter/material.dart';
import 'package:at_contact/at_contact.dart';
import 'package:atsign_atmosphere_app/services/backend_service.dart';
import 'package:atsign_atmosphere_app/utils/text_strings.dart';
import 'package:atsign_atmosphere_app/view_models/base_model.dart';

class ContactProvider extends BaseModel {
  List<AtContact> contactList = [];
  List<AtContact> blockContactList = [];
  List<AtContact> selectedContacts = [];
  List<String> allContactsList = [];
  String selectedAtsign;
  BackendService backendService = BackendService.getInstance();

  String Contacts = 'contacts';
  String AddContacts = 'add_contacts';
  String GetContacts = 'get_contacts';
  String DeleteContacts = 'delete_contacts';
  String BlockContacts = 'block_contacts';
  String SelectContact = 'select_contacts';
  bool limitReached = false;

  ContactProvider() {
    initContactImpl();
  }
  // static ContactProvider _instance = ContactProvider._();
  Completer completer;

  initContactImpl() async {
    try {
      setStatus(Contacts, Status.Loading);
      completer = Completer();
      atContact =
          await AtContactsImpl.getInstance(backendService.currentAtsign);
      completer.complete(true);
      setStatus(Contacts, Status.Done);
    } catch (error) {
      print("error =>  $error");
      setError(Contacts, error.toString());
    }
  }

  // factory ContactProvider() => _instance;

  List<Map<String, dynamic>> contacts = [];
  static AtContactsImpl atContact;

  Future getContacts() async {
    Completer c = Completer();
    try {
      setStatus(GetContacts, Status.Loading);
      contactList = [];
      allContactsList = [];
      await completer.future;
      contactList = await atContact.listContacts();
      List<AtContact> tempContactList = [...contactList];
      print("list =>  $contactList");
      int range = contactList.length;

      for (int i = 0; i < range; i++) {
        print("is blocked => ${contactList[i].blocked}");
        allContactsList.add(contactList[i].atSign);
        if (contactList[i].blocked) {
          print("herererr");
          tempContactList.remove(contactList[i]);
        }
      }
      contactList = tempContactList;
      contactList.sort(
          (a, b) => a.atSign.substring(1).compareTo(b.atSign.substring(1)));
      print("list =>  $contactList");
      setStatus(GetContacts, Status.Done);
      c.complete(true);
    } catch (e) {
      print("error here => $e");
      setStatus(GetContacts, Status.Error);
      c.complete(true);
    }
    return c.future;
  }

  blockUnblockContact({String atSign, bool blockAction}) async {
    try {
      setStatus(BlockContacts, Status.Loading);
      if (atSign[0] != '@') {
        atSign = '@' + atSign;
      }
      AtContact contact = AtContact(
        atSign: atSign,
        // personas: ['persona1', 'persona22', 'persona33'],
      );

      // contact.type = ContactType.Institute;
      contact.blocked = blockAction;
      await atContact.update(contact);
      if (blockAction == true) {
        await getContacts();
      } else {
        fetchBlockContactList();
      }
    } catch (error) {
      setError(BlockContacts, error.toString());
    }
  }

  fetchBlockContactList() async {
    try {
      setStatus(BlockContacts, Status.Loading);
      blockContactList = await atContact.listBlockedContacts();
      print("block contact list => $blockContactList");
      setStatus(BlockContacts, Status.Done);
    } catch (error) {
      setError(BlockContacts, error.toString());
    }
  }

  deleteAtsignContact({String atSign}) async {
    try {
      setStatus(DeleteContacts, Status.Loading);
      var result = await atContact.delete('$atSign');
      print("delete result => $result");
      await getContacts();
      setStatus(DeleteContacts, Status.Done);
    } catch (error) {
      setError(DeleteContacts, error.toString());
    }
  }

  bool isContactPresent = false;
  bool isLoading = false;
  String getAtSignError = '';
  bool checkAtSign;

  Future addContact({String atSign}) async {
    if (atSign == null || atSign == '') {
      getAtSignError = TextStrings().emptyAtsign;
      setError(AddContacts, '_error');
      isLoading = false;
      return true;
    } else if (atSign[0] != '@') {
      atSign = '@' + atSign;
    }
    Completer c = Completer();
    try {
      isContactPresent = false;
      isLoading = true;
      getAtSignError = '';
      AtContact contact = AtContact();
      setStatus(AddContacts, Status.Loading);

      checkAtSign = await backendService.checkAtsign(atSign);
      if (!checkAtSign) {
        getAtSignError = TextStrings().unknownAtsign(atSign);
        setError(AddContacts, '_error');
        isLoading = false;
      } else {
        contactList.forEach((element) async {
          if (element.atSign == atSign) {
            getAtSignError = TextStrings().atsignExists(atSign);
            isContactPresent = true;
            return true;
          }
          isLoading = false;
        });
      }
      if (!isContactPresent && checkAtSign) {
        var details = await backendService.getContactDetails(atSign);
        contact = AtContact(
          atSign: atSign,
          tags: details,
        );
        var result = await atContact.add(contact);
        print(result);
        isLoading = false;
        Navigator.pop(NavService.navKey.currentContext);
        await getContacts();
      }
      c.complete(true);
      isLoading = false;
      setStatus(AddContacts, Status.Done);
    } catch (e) {
      c.complete(true);
      setStatus(AddContacts, Status.Error);
    }
    return c.future;
  }

  selectContacts(AtContact contact) {
    setStatus(SelectContact, Status.Loading);
    try {
      print('IN SELECT;');
      if (selectedContacts.length <= 3) {
        print('in 1');
        selectedContacts.add(contact);
      } else {
        print('in 2');
        limitReached = true;
      }

      setStatus(SelectContact, Status.Done);
      print('LIMIT REACHED=====>$limitReached');
    } catch (error) {
      setError(SelectContact, error.toString());
    }
  }

  removeContacts(AtContact contact) {
    setStatus(SelectContact, Status.Loading);
    try {
      selectedContacts.remove(contact);
      if (selectedContacts.length <= 3) {
        limitReached = false;
      } else {
        limitReached = true;
      }
      setStatus(SelectContact, Status.Done);
    } catch (error) {
      setError(SelectContact, error.toString());
    }
  }
}
