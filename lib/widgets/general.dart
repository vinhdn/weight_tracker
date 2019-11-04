import 'package:flutter/material.dart';

borderLeft({double radius = 5}) => BorderRadius.only(topLeft: Radius.circular(radius), bottomLeft: Radius.circular(radius));
const borderRight = BorderRadius.only(topRight: Radius.circular(5), bottomRight: Radius.circular(5));
const borderAll = BorderRadius.all(Radius.circular(5));
const borderTop = BorderRadius.vertical(top: Radius.circular(5));
const borderBottom = BorderRadius.vertical(bottom: Radius.circular(5));
const boxShadow = [BoxShadow(blurRadius: 1, offset: Offset(0.5, 0.5), color: Colors.black54)];

Color hexToColor(String code) {
    return new Color(int.parse(code.substring(1, 7), radix: 16) + 0xFF000000);
}