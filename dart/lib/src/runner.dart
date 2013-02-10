library egb_runner;

import 'dart:async';
import 'dart:isolate';

import 'shared/utils.dart';

import 'interface/interface.dart';
import 'persistence/storage.dart';
import 'persistence/savegame.dart';
import 'persistence/player_profile.dart';
import 'shared/user_interaction.dart';
import 'shared/message.dart';

/**
 * EgbRunner manages communication between the Book and the Interface.
 * It is interface-agnostic.
 */
class EgbRunner {
  ReceivePort _receivePort;
  SendPort _scripterPort;
  EgbInterface _interface;
  
  EgbPlayerProfile _playerProfile;
  
  bool started = false;
  bool ended = false;
  
  StreamController<String> _streamController;
  Stream<String> get stream => _streamController.stream;
  Stream<String> get endOfBookReached => stream.where((value) => value == "END");
  
  EgbRunner(this._receivePort, this._scripterPort, 
      this._interface, this._playerProfile) {
    _streamController = new StreamController();
    
    _interface.stream.listen((playerIntent) {
      switch (playerIntent.type) {
        case (PlayerIntent.RESTART):
          _scripterPort.send(new EgbMessage.Start().toJson(), 
              _receivePort.toSendPort());
          started = true;
          break;
        case (PlayerIntent.QUIT):
          stop();
          break;
        case (PlayerIntent.LOAD):
          // load latest saved state for the bookUid from playerProfile
          // TODO: dry with below
          _playerProfile.load((playerIntent as LoadIntent).uid)
          .then((EgbSavegame savegame) {
            if (savegame == null) {
              // no savegames for this egamebook
              _scripterPort.send(new EgbMessage.Start().toJson(), 
                  _receivePort.toSendPort());
            } else {
              _scripterPort.send(savegame.toMessage(EgbMessage.LOAD_GAME).toJson(), 
                  _receivePort.toSendPort());
            }
          });
          started = true;
          break;
      }
    });
    
    _receivePort.receive(receiveFromScripter);
  }
  
  void run() {
    _interface.setup();
    _scripterPort.send(
        new EgbMessage.GetBookUid().toJson(),
        _receivePort.toSendPort()
    );
  }
  
  void stop() {
    _playerProfile.close();
    _interface.close();
    _scripterPort.send(new EgbMessage.Quit().toJson());
    _receivePort.close();
  }
  
  /**
   * Utilify function [_send] sends message through the [_runnerPort] to the
   * Runner.
   */
  void _send(EgbMessage message) {
    if (_scripterPort == null) throw new StateError("Cannot send message "
                                             "when _scripterPort is null.");
    _scripterPort.send(message.toJson(), _receivePort.toSendPort());
  }
  
  /**
   * Main loop function. Receives a message from scripter, and either
   * responds immediately, or asks for input via [interface], then responds.
   */
  void receiveFromScripter(String messageJson, SendPort replyTo) {
    EgbMessage message = new EgbMessage.fromJson(messageJson);
    _scripterPort = replyTo;
    
    switch (message.type) {
      case EgbMessage.END_OF_BOOK:
        _streamController.sink.add("END");  // send the info to interface
        ended = true;  // TODO: not needed, Runner is not ended, Scripter is
        return;
      case EgbMessage.SEND_BOOK_UID:
        _startNewSession(message);
        return;
      case EgbMessage.SAVE_GAME:
        EgbSavegame savegame = new EgbSavegame.fromMessage(message);
        _playerProfile.save(savegame);
        _interface.addSavegameBookmark(savegame);
        _send(new EgbMessage.Continue());
        return;
      case EgbMessage.SAVE_PLAYER_CHRONOLOGY:
        _playerProfile.savePlayerChronology(message.listContent);
        _send(new EgbMessage.Continue());
        return;
      case EgbMessage.TEXT_RESULT:
        _interface.showText(message.strContent);
        _send(new EgbMessage.Continue());
        return;
      case EgbMessage.NO_RESULT:
        // No visible result from Scripter. Continuing.
        _send(new EgbMessage.Continue());
        return;
      case EgbMessage.POINTS_AWARD:
        // TODO: make into stream event, show toast, update points...
        var text;
        if (message.strContent != null) {
          text = "+${message.intContent} points for ${message.strContent}";
        } else {
          text = "+${message.intContent} points";
        }
        _interface.showText(text);
        _send(new EgbMessage.Continue());
        return;
      case EgbMessage.SHOW_CHOICES:
        _showChoices(message);
        return;
    }
  }

  /**
   * Shows choices, waits for the interface and player to pick one of them,
   * then sends the result back to Scripter.
   */
  void _showChoices(EgbMessage message) {
    if (message.listContent[0] != null) {
      // Show question text if available.
      _interface.showText(message.listContent[0]);
    }
    
    EgbChoiceList choices = new EgbChoiceList.fromMessage(message);
    
    if (choices.length == 1 && choices[0].string.trim() == "") {
      // An auto-choice (without a string) means we should pick it silently.
      _send(new EgbMessage.OptionSelected(choices[0].hash));
    } else {
      // Let player choose.
      _interface.showChoices(choices)
      .then((int hash) {
        if (hash != null) {
          _send(new EgbMessage.OptionSelected(hash));
        } else {
          // User wants to quit (hash == null).
          stop();
        }
      });
    }
  }
  
  /**
   * Runner receives gamebook UID from Scripter, typically just after opening
   * the session with this particular book. If [playerProfile] has any saves
   * for this particular book, Runner will automatically load the most recent.
   * If not, Runner will just start the book from start.
   */
  EgbMessage _startNewSession(EgbMessage message) {
    // Get bookUid from Scripter.
    _playerProfile.currentEgamebookUid = message.strContent;
    // Load latest saved state for the bookUid from playerProfile.
    _playerProfile.loadMostRecent()
    .then((EgbSavegame savegame) {
      if (savegame == null) {
        // No savegames for this egamebook.
        _send(new EgbMessage.Start());
      } else {
        _playerProfile.loadPlayerChronology()
        .then((List<String> playerChronology) {
          // Create LOAD_GAME message with scripter state in strContent (json).
          var loadgameMsg = savegame.toMessage(EgbMessage.LOAD_GAME);
          // Add playerChronology as listContent.
          loadgameMsg.listContent = playerChronology;
          _send(loadgameMsg);
        });
        
      }
    });
    started = true;
  }
  
}