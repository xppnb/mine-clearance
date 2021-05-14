import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mine_clearance_2/BoardSquare.dart';

enum ImageType {
  zero,
  one,
  two,
  three,
  four,
  bomb,
  facingDown,
  flagged,
}

class GameBody extends StatefulWidget {
  Size size;

  GameBody({this.size});

  @override
  _GameBodyState createState() => _GameBodyState();
}

class _GameBodyState extends State<GameBody> {
  int rowCount;
  int columnCount;

  int rowSize = 50;
  int columnSize = 50;

  List<List<BoardSquare>> board = [];
  List<List<bool>> openSquares;
  List<List<bool>> flagSquares;
  List<List<Image>> imageList = [];

  int bombCount;

  //记录放格的数量
  int squareNum;

  //随机数最大数
  int maxProbability = 15;

  //炸弹的数字
  int bombProbability = 3;

  Image image;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    initGame();
  }

  void initGame() {
    setState(() {
      imageList = [];

      rowCount =
          (widget.size.height / rowSize - (rowSize % 60).clamp(-1, 2)).floor();
      if(rowCount % 2 != 0){
        rowCount = rowCount - 1;
      }
      columnCount = (widget.size.width / columnSize).floor();

      board = List.generate(rowCount,
          (index) => List.generate(columnCount, (index) => BoardSquare()));

      bombCount = 0;
      squareNum = rowCount * columnCount;

      //随机生成雷
      Random random = new Random();
      List.generate(
          rowCount,
          (index1) => List.generate(columnCount, (index) {
                int randomNum = random.nextInt(maxProbability);
                if (randomNum < bombProbability) {
                  board[index1][index].hasBoob = true;
                  bombCount++;
                }
              }));

      openSquares = List.generate(
          rowCount, (index) => List.generate(columnCount, (index) => false));

      flagSquares = List.generate(
          rowCount, (index) => List.generate(columnCount, (index) => false));

      //查询附近的编号
      List.generate(
          rowCount,
          (i) => List.generate(columnCount, (j) {
                if (i > 0 && j > 0) {
                  if (board[i - 1][j - 1].hasBoob) {
                    board[i][j].aroundBoob++;
                  }
                }
                if (i > 0) {
                  if (board[i - 1][j].hasBoob) {
                    board[i][j].aroundBoob++;
                  }
                }
                if (i > 0 && j < columnCount - 1) {
                  if (board[i - 1][j + 1].hasBoob) {
                    board[i][j].aroundBoob++;
                  }
                }
                if (j > 0) {
                  if (board[i][j - 1].hasBoob) {
                    board[i][j].aroundBoob++;
                  }
                }
                if (j < columnCount - 1) {
                  if (board[i][j + 1].hasBoob) {
                    board[i][j].aroundBoob++;
                  }
                }
                if (i < rowCount - 1 && j > 0) {
                  if (board[i + 1][j - 1].hasBoob) {
                    board[i][j].aroundBoob++;
                  }
                }
                if(i < rowCount - 1){
                  if(board[i + 1][j].hasBoob){
                    board[i][j].aroundBoob++;
                  }
                }
                if (i < rowCount - 1 && j < columnCount - 1) {
                  if (board[i + 1][j + 1].hasBoob) {
                    board[i][j].aroundBoob++;
                  }
                }
              }));
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Row> rowList = [];
    List<Image> images = [];
    imageList = [];
    List.generate(rowCount, (i) {
      List.generate(columnCount, (j) {
        Image image;
        if (openSquares[i][j] == false) {
          if (flagSquares[i][j]) {
            print("变成棋子了");
            image = getImage(ImageType.flagged);
          } else {
            image = getImage(ImageType.facingDown);
            print("普通格子");
          }
        } else {
          if (board[i][j].hasBoob) {
            print("显示爆炸格子");
            image = getImage(ImageType.bomb);
          } else {
            print("显示了${board[i][j].aroundBoob}");
            image = getImage(getImageTypeNumber(board[i][j].aroundBoob));
          }
        }
        images.add(image);
        //imageList.addAll(List.generate(i, (index) => List.generate(j, (index) => image)));
        setState(() {});
      });
      setState(() {
        imageList.add(images);
        images = [];
      });
    });




    addList(rowList);

    return SafeArea(
      child: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  margin: EdgeInsets.only(bottom: 20),
                  height: 40,
                  width: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: Colors.yellowAccent, shape: BoxShape.circle),
                  child: IconButton(
                    padding: EdgeInsets.all(0),
                    icon: Icon(
                      Icons.tag_faces,
                      color: Colors.black,
                      size: 40,
                    ),
                    onPressed: () {
                      initGame();
                    },
                  ),
                ),
                // Text("还有${bombCount}个雷")
              ],
            ),
            Column(
              children: rowList,
            )
          ],
        ),
      ),
    );
  }

  void addList(List<Row> rowList) {
    for (int i = 0; i < rowCount; i++) {
      List<InkWell> columnList = [];
      for (int j = 0; j < columnCount; j++) {
        columnList.add(InkWell(
          onTap: () {
            setState(() {
              print(board[i][j].aroundBoob.toString());
              print(board[i][j].hasBoob);
              imageList = [];
              if (board[i][j].hasBoob) {
                ///失败弹窗
                print("失败了，弹窗了");
                loseGame().then((value) => initGame());
              }

              ///判断周围是否都是0，是0就用递归的方法找出
              ///不然的话就将状态改为打开的格子，并且让格子总数减少1

              if (board[i][j].aroundBoob == 0) {
                handleTap(i, j);
              } else {
                openSquares[i][j] = true;
                squareNum = squareNum - 1;
              }

              if (squareNum <= bombCount) {
                winGame().then((value) => initGame());

                print("赢下游戏");
              }


            });
          },
          onLongPress: () {
            if (openSquares[i][j] != true) {
              setState(() {
                flagSquares[i][j] = !flagSquares[i][j];
                if (flagSquares[i][j] == board[i][j].hasBoob && flagSquares[i][j] == true) {
                  setState(() {
                    bombCount--;
                  });
                }else if(board[i][j].hasBoob){
                  setState(() {
                    bombCount ++;
                  });
                }

              });
            }

            if (bombCount <= 0) {
              winGame().then((value) => initGame());
            }
          },
          child: Container(
            height: rowSize.toDouble(),
            width: columnSize.toDouble(),
            child: imageList[i][j],
          ),
        ));
      }
      rowList.add(Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: columnList,
      ));
    }
  }

  void handleTap(int i, int j) {
    openSquares[i][j] = true;
    squareNum = squareNum - 1;
    if (i > 0) {
      if (!board[i - 1][j].hasBoob && openSquares[i - 1][j] != true) {
        if (board[i][j].aroundBoob == 0) {
          handleTap(i - 1, j);
        }
      }
    }
    if (j > 0) {
      if (!board[i][j - 1].hasBoob && openSquares[i][j - 1] != true) {
        if (board[i][j].aroundBoob == 0) {
          handleTap(i, j - 1);
        }
      }
    }
    if (i < rowCount - 1) {
      if (!board[i + 1][j].hasBoob && openSquares[i + 1][j] != true) {
        if (board[i][j].aroundBoob == 0) {
          handleTap(i + 1, j);
        }
      }
    }
    if (j < columnCount - 1) {
      if (!board[i][j + 1].hasBoob && openSquares[i][j + 1] != true) {
        if (board[i][j].aroundBoob == 0) {
          handleTap(i, j + 1);
        }
      }
    }
    setState(() {});
  }

  Future loseGame() {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Game Over"),
            content: Text("You lose"),
            actions: [
              FlatButton(
                  onPressed: () {
                    setState(() {
                      initGame();
                      Navigator.pop(context);
                    });
                  },
                  child: Text("Play Again"))
            ],
          );
        });
  }

  Future winGame() {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Congratulations"),
            content: Text("You Win"),
            actions: [
              FlatButton(
                  onPressed: () {
                    setState(() {
                      initGame();
                      Navigator.pop(context);
                    });
                  },
                  child: Text("Play Again"))
            ],
          );
        });
  }

  Image getImage(ImageType type) {
    switch (type) {
      case ImageType.bomb:
        return Image.asset("images/bomb.png");
      case ImageType.facingDown:
        return Image.asset("images/facingDown.png");
      case ImageType.flagged:
        return Image.asset("images/flagged.png");
      case ImageType.zero:
        return Image.asset('images/0.png');
      case ImageType.one:
        return Image.asset('images/1.png');
      case ImageType.two:
        return Image.asset('images/2.png');
      case ImageType.three:
        return Image.asset('images/3.png');
      case ImageType.four:
        return Image.asset('images/4.png');
      default:
        return null;
    }
  }

  ImageType getImageTypeNumber(int number) {
    switch (number) {
      case 0:
        return ImageType.zero;
      case 1:
        return ImageType.one;
      case 2:
        return ImageType.two;
      case 3:
        return ImageType.three;
      case 4:
        return ImageType.four;
      default:
        return null;
    }
  }
}
