import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
//Ler arquivos do Android e do IOS
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(home: Home(), debugShowCheckedModeBanner: false,));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  
  // Controlador do input
  final _toDoControler = TextEditingController();

  // Lista para armazenar as tarfas
  List _toDoList = [];

  // Mapa que acabamos de remover
  Map<String, dynamic> _lastRemoved;
  // Pega a posição que foi removida, pois quero que volte na mesma posição
  int _lastRemovedPos;


  // Executa sempre que iniciamos a tela
  @override
  void initState() {
    super.initState();
    
    // Chama a função assim que retornar os dados
    _readData().then((data) {
      setState(() {
        // Passa um Json para a lsita
        _toDoList = json.decode(data);
      });
    });
  }

  void _addToDo() {
    setState(() {
      // Json sempre vai ser String e dynamic
      Map<String, dynamic> newToDo = Map();
      newToDo["title"] = _toDoControler.text;
      _toDoControler.text = "";
      newToDo["ok"] = false;
      _toDoList.add(newToDo);
      print(_toDoList);
      _saveData();
    });
  }

// Coloquei future para esperar um segundo para dar um efeito legal
  Future<Null> _refresh() async{
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      // Função para ordernação
     _toDoList.sort((a, b){
      if(a["ok"] && !b["ok"]) return 1;
      else if(!a["ok"] && b["ok"]) return -1;
      else return 0;
    });

    _saveData(); 
    });

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de Tarefas"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child: Row(
              children: <Widget>[
                // Expandir até o máximo que puder
                Expanded(
                  child: TextField(
                    controller: _toDoControler,
                    decoration: InputDecoration(
                        labelText: "Nova Tarefa",
                        labelStyle: TextStyle(color: Colors.blueAccent)),
                  ),
                ),
                RaisedButton(
                  color: Colors.blueAccent,
                  child: Text("ADD"),
                  textColor: Colors.white,
                  onPressed: _addToDo,
                )
              ],
            ),
          ),
          Expanded(
            // Faz alguma ação quando puxo a lista pra baixo
            child: RefreshIndicator(
              onRefresh: _refresh,
              // Criar uma lista. E o builder cria a lisra conforme vou rolando a tela
              child: ListView.builder(
                padding: EdgeInsets.only(top: 10.0),
                // Quantidade de itens da lista
                itemCount: _toDoList.length,
                // Criar os elementos da lista
                itemBuilder: buildItem,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget buildItem(BuildContext context, int index) {
    // Dismissible permite arrastar o item para exlcuir
    return Dismissible(
      // Precisa da key para o sistema saber qual estou deslizando
      // Tempo atual em miicrosegundos
      key: Key(DateTime.now().microsecondsSinceEpoch.toString()),
      // Colocar o background que aparce atrás quando arrasto
      background: Container(
        color: Colors.red,
        child: Align(
          // Possicionamento na tela x, y
          alignment: Alignment(-0.9, 0.0),
          child: Icon(Icons.delete, color: Colors.white),
        ),
      ),
      // Define a direção do Dismissible
      direction: DismissDirection.startToEnd,
      // ListTile com checkbox
      child: CheckboxListTile(
        title: Text(_toDoList[index]["title"]),
        value: _toDoList[index]["ok"],
        secondary: CircleAvatar(
          child: Icon(_toDoList[index]["ok"] ? Icons.check : Icons.error),
        ),
        onChanged: (c) {
          setState(() {
            _toDoList[index]["ok"] = c;
            _saveData();
          });
        },
      ),
      // Função que faço quando 
      // Posso dar um Dismis para cada direção que eu definir
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = Map.from(_toDoList[index]); // Dupliaca o item que estou tentando remover
          _lastRemovedPos = index; // Pegar o index do item.
          _toDoList.removeAt(index);

          _saveData();

          // Mensagem na SnackBar
          final snack = SnackBar(
            // Conteudo da snack
            content: Text("Tarefa \"${_lastRemoved["title"]}\" removida"),
            // Ação da Snack
            action: SnackBarAction(
              label: "Desfazer",
              // Função que quando for clicada retorno o item excluido
              onPressed: () {
                setState(() {
                  // Index e o item removido
                  _toDoList.insert(_lastRemovedPos, _lastRemoved);
                  _saveData();
                });
              },
            ),
            // Duração da mensagem
            duration: Duration(seconds: 2),
          );
          // Remover pilha de snackBar
          Scaffold.of(context).removeCurrentSnackBar();  
          // Mostra o SnackBar 
          Scaffold.of(context).showSnackBar(snack);
        });
      },
    );
  }

  // Pegar arquivo
  Future<File> _getFile() async {
    // Pega o diretorio onde armazeno os dados
    final directory = await getApplicationDocumentsDirectory();
    // Caminho do diretorio, e dei o nome de data
    return File("${directory.path}/data.json");
  }

  // Salvar os dados
  Future<File> _saveData() async {
    // Transforma a lista em Json
    String data = json.encode(_toDoList);
    // Pega o arquivo onde vou salvar os dados
    final file = await _getFile();
    // Escreve os dados dentro do arquivo
    return file.writeAsString(data);
  }

  // Ler os arquivos
  Future<String> _readData() async {
    // Tentar ler os arquivos
    try {
      // Tentar ler o arquivo
      final file = await _getFile();
      // Leitor do arquivo
      return file.readAsString();
    } catch (e) {
      // Casso dê errado, retonar null
      return null;
    }
  }
}
