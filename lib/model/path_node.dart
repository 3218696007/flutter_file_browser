class PathNode {
  final String path;
  PathNode? parent;
  PathNode? child;

  PathNode(this.path);

  void setChild(PathNode newChild) {
    _freeChildAndAfter();
    newChild.parent = this;
    child = newChild;
  }

  void _freeChildAndAfter() {
    var unuseNode = child;
    while (unuseNode != null) {
      var next = unuseNode.child;
      unuseNode.parent = null;
      unuseNode.child = null;
      unuseNode = next;
    }
    child = null;
  }
}
