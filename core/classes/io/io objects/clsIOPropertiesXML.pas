unit clsIOPropertiesXml;

interface
uses
  classes,
  sysUtils,
  variants,
  activeX,
  msXML,

  clsStringUtils,
  clsException,
  clsAbstractIOObject,
  clsClassKit,
  clsVariantConversion,
  clsAbstractConfig;

type
  eIOPropertiesXML = class(cException);

  //IO
  cIOPropertiesXML = class(cAbstractIOOProperties)
  private
    const
    NODE_PROPERTIES_NAME      = 'properties';

    XML_FILE_NOT_ASSIGNED     = 'XML file not assigned';
    DATATYPE_NOT_SUPPORTED    = 'datatype not supported';

    TYPE_ATTRIBUTE            = 'type';
    SECTION_TYPE              = 'section';

    XPATH_DESCENDANT          = '/';
    XPATH_DESCENDANT_OR_SELF  = '//';
    XPATH_ANY_NODE            = '*';
    XPATH_CHILDS_NODES        = XPATH_DESCENDANT_OR_SELF + XPATH_ANY_NODE;
  private
    fUseInMemory  : boolean;
    fFileName     : string;
    fRootNodeName : string;
    fLoaded       : boolean;

    fXMLDoc       : iXMLDOMDocument2;

    procedure   loadXML(aContent: string);
    function    getSection(aSection: string): iXMLDOMNode;

    function    isLoaded: boolean;
  protected
    procedure   commit; override;
  public
    procedure   clear; override;

    procedure   saveToStream(aStream: tStream); override;
    procedure   loadFromStream(aStream: tStream); override;

    procedure   load; override;

    procedure   setUseInMemory(aValue: boolean);
    function    isUseInMemory: boolean;

    procedure   setFileName(aFileName: string);
    procedure   setRootNodeName(aName: string);

    function    exists(aSection: string): boolean; override;
    procedure   iterateSections(aIteratorProc: tSectionsIteratorProc); override;

    function    read(aSection: string; aType: tDataType; aItemName: string; const aDefValue: variant): variant; override;
    procedure   write(aSection: string; aType: tDataType; aItemName: string; const aValue: variant); override;

    constructor create;
    destructor  destroy; override;

    property    fileName: string read fFileName;
  end;

implementation


{ cIOPropertiesXML }

procedure cIOPropertiesXML.clear;
begin
  loadXML('');
  setRootNodeName(fRootNodeName);
end;

procedure cIOPropertiesXML.commit;
begin
  if (not fUseInMemory) and (fFileName <> '') then begin
    fXMLDoc.save(fFileName);
  end;
end;

constructor cIOPropertiesXML.create;
begin
  inherited create;

  fLoaded:= false;
  fUseInMemory:= true;
  fFileName:= '';

  fXMLDoc:= coDOMDocument.create;
  fXMLDoc.async:= false;
end;

destructor cIOPropertiesXML.destroy;
begin
  if assigned(fXMLDoc) then begin
    commit;
    fXMLDoc:= nil;
  end;

  inherited;
end;

function cIOPropertiesXML.exists(aSection: string): boolean;
var
  sectionNode: iXMLDOMNode;
begin
  result:= false;
  sectionNode:= getSection(aSection);
  result:= assigned(sectionNode);
end;

function cIOPropertiesXML.getSection(aSection: string): iXMLDOMNode;
var
  srcNode: iXMLDOMNode;
  root: iXMLDOMNode;
begin
  result:= nil;
  root:= fXMLDoc.documentElement;

  srcNode:= fXMLDoc.selectSingleNode(format('%s%s', [XPATH_DESCENDANT_OR_SELF, aSection]));
  result:= srcNode;
end;

function cIOPropertiesXML.isLoaded: boolean;
begin
  result:= fLoaded;
end;

function cIOPropertiesXML.isUseInMemory: boolean;
begin
  result:= fUseInMemory;
end;

procedure cIOPropertiesXML.iterateSections(aIteratorProc: tSectionsIteratorProc);
var
  nodes: iXMLDOMNodeList;
  root: iXMLDOMNode;

  typeAttribute: iXMLDOMNode;

  i: integer;
  sectionIndex: integer;
begin
  inherited iterateSections(aIteratorProc);

  root:= fXMLDoc.documentElement;

  nodes:= fXMLDoc.selectNodes(XPATH_CHILDS_NODES);

  sectionIndex:= 0;
  for i := 0 to nodes.length - 1 do begin
    typeAttribute:= nodes.item[i].attributes.getNamedItem(TYPE_ATTRIBUTE);
    if not assigned(typeAttribute) then begin
      continue;
    end;

    aIteratorProc(nodes.item[i].nodeName, sectionIndex);
    inc(sectionIndex);
  end;
end;

procedure cIOPropertiesXML.load;
begin
  if (not fUseInMemory) and (fFileName <> '') then begin
    fXMLDoc.load(fFileName);
    fLoaded:= true;
  end;
end;

procedure cIOPropertiesXML.loadFromStream(aStream: tStream);
var
  content: string;
begin
  setLength(content, aStream.size);

  aStream.read(content[1], aStream.size);

  loadXML(content);
end;

procedure cIOPropertiesXML.loadXML(aContent: string);
begin
  fXMLDoc.loadXML(aContent);
end;

function cIOPropertiesXML.read(aSection: string; aType: tDataType; aItemName: string; const aDefValue: variant): variant;
var
  srcNode: iXMLDOMNode;
  root: iXMLDOMNode;

  propertyNode: iXMLDOMNode;
  propValue: variant;
begin
  result:= null;

  //lazy load
  if (not fUseInMemory) and (not fLoaded) then begin
    load;
  end;


  if (aType = dtNotSupported) then begin
    exit;
  end;

  root:= fXMLDoc.documentElement;

  srcNode:= fXMLDoc.selectSingleNode(format('%s%s', [XPATH_DESCENDANT_OR_SELF, aSection]));
  if (assigned(srcNode)) then begin
    propertyNode:= srcNode.selectSingleNode(aItemName);
    if (assigned(propertyNode)) then begin
      propValue:= propertyNode.text;
    end else begin
      result:= aDefValue;
      exit;
    end;
  end else begin
    result:= aDefValue;
    exit;
  end;

  case aType of

    dtByteArray:
    begin
      result:= cStringUtils.stringToBytesArray(propValue);
    end;

    dtDateTime:
    begin
      result:= strToDateTime(propValue);
    end

    else begin
      result:= propValue;
    end;

  end;
end;

procedure cIOPropertiesXML.saveToStream(aStream: tStream);
var
  content: string;
begin
  content:= fXMLDoc.XML;

  aStream.write(content[1], length(content) * sizeOf(char));
end;

procedure cIOPropertiesXML.setFileName(aFileName: string);
begin
  fFileName:= aFileName;

  forceDirectories(extractFilePath(fFileName));
end;

procedure cIOPropertiesXML.setRootNodeName(aName: string);
var
  rootNode: iXMLDOMNode;
begin
  fRootNodeName:= aName;

  if not assigned(fXMLDoc) then begin
    exit;
  end;

  rootNode:= fXMLDoc.documentElement;

  if (not assigned(rootNode)) then begin
    rootNode:= fXMLDoc.createNode(NODE_ELEMENT, aName, '');

    fXMLDoc.appendChild(rootNode);
  end else begin
    rootNode.text:= aName;
  end;

end;

procedure cIOPropertiesXML.setUseInMemory(aValue: boolean);
begin
  fUseInMemory:= aValue;
end;

procedure cIOPropertiesXML.write(aSection: string; aType: tDataType; aItemName: string; const aValue: variant);
var
  destNode: iXMLDOMNode;
  root: iXMLDOMNode;

  typeAttribute: iXMLDOMAttribute;

  propertyNode: iXMLDOMNode;
begin
  root:= fXMLDoc.documentElement;
  if not assigned(root) then begin
    setRootNodeName(NODE_PROPERTIES_NAME);
    root:= fXMLDoc.documentElement;
  end;


  destNode:= getSection(aSection);
  if (not assigned(destNode)) then begin
    destNode:= fXMLDoc.createNode(NODE_ELEMENT, aSection, '');

    typeAttribute:= fXMLDoc.createAttribute(TYPE_ATTRIBUTE);
    typeAttribute.value:= SECTION_TYPE;

    destNode.attributes.setNamedItem(typeAttribute);
    root.appendChild(destNode);

    propertyNode:= fXMLDoc.createNode(NODE_ELEMENT, aItemName, '');

    destNode.appendChild(propertyNode);
  end else begin
    propertyNode:= destNode.selectSingleNode(aItemName);
    if (not assigned(propertyNode)) then begin
      propertyNode:= fXMLDoc.createNode(NODE_ELEMENT, aItemName, '');
      destNode.appendChild(propertyNode);
    end;
  end;


  case aType of

    dtNotSupported:
    begin
      exit;
    end;

    dtDateTime:
    begin
      propertyNode.text:= dateTimeToStr(aValue);
    end;

    dtByteArray    : begin
      propertyNode.text:= cStringUtils.bytesArrayToString(aValue);
    end else begin
      propertyNode.text:= aValue;
    end;
  end;
end;

end.
