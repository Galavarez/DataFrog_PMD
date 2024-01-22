unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  EditBtn, PNG;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button_Build_File: TButton;
    Button_Clear_All: TButton;
    Button_Get_Preview_From_File: TButton;
    EditButton_Path_To_Games: TEditButton;
    EditButton_Path_To_Png: TEditButton;
    Edit_Name_Game: TEdit;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    GroupBox3: TGroupBox;
    GroupBox4: TGroupBox;
    ImageList: TImageList;
    Image_Preview: TImage;
    procedure Button_Build_File_OnClick(Sender: TObject);
    procedure Button_Clear_AllClick(Sender: TObject);
    procedure Button_Get_Preview_From_File_OnClick(Sender: TObject);
    procedure EditButton_Path_To_Games_OnButtonClick(Sender: TObject);
    procedure EditButton_Path_To_Png_OnButtonClick(Sender: TObject);

  private

  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

// Получаем preview
procedure TForm1.Button_Get_Preview_From_File_OnClick(Sender: TObject);
var
  FS, FS2: TFileStream;
  SIZE_PNG : LongInt;
  ARRAY_BYTES_PNG : TByteArray;
  PATH_IN_FILE, NAME_PMD_FILE , NAME_PNG_FILE : String;
  OD: TOpenDialog;
begin
  //
  OD := TOpenDialog.Create(Self);
  //
  if OD.Execute then
  begin
    // Открываем файл
    PATH_IN_FILE := OD.FileName;
    // Получаем имя файла с расширением
    NAME_PMD_FILE := ExtractFileName(PATH_IN_FILE);
    // Меняем расширение с pmd на png
    NAME_PNG_FILE := StringReplace(NAME_PMD_FILE, '.pmd', '.png', [rfReplaceAll, rfIgnoreCase]);

    // Получам размер png
    FS := TFileStream.Create(PATH_IN_FILE, fmOpenRead);
    FS.Position:= 512;
    FS.Read(SIZE_PNG, 4);
    // Получам массив байт png
    FS.Position:= 520;
    FS.Read(ARRAY_BYTES_PNG, SIZE_PNG);
    FS.Free;

    // Сохраняю массив байт png в файл
    FS2 := TFileStream.Create(NAME_PNG_FILE, fmCreate);
    FS2.Write(ARRAY_BYTES_PNG, SIZE_PNG);
    FS2.Free;

    // Показываем превьюшку
    Image_Preview.Picture.LoadFromFile(NAME_PNG_FILE);

    // Загружаем путь к превьюшке
    EditButton_Path_To_Png.Text:= ExtractFileDir(Application.ExeName) + '\' + NAME_PNG_FILE;

    // Удаляем превью
    //DeleteFile(ExtractFileDir(Application.ExeName) + '\' + NAME_PNG_FILE );
  end;
end;

// Клик на Button Rom
procedure TForm1.EditButton_Path_To_Games_OnButtonClick(Sender: TObject);
var
  OD: TOpenDialog;
  NAME_FILE, EXTENTION, STR : String;
begin
  OD := TOpenDialog.Create(Self);
  if OD.Execute then
  begin
    EditButton_Path_To_Games.Text:= OD.FileName;
    NAME_FILE := ExtractFileName(OD.FileName);
    EXTENTION := ExtractFileExt(OD.FileName);
    STR := StringReplace(NAME_FILE, EXTENTION, '', [rfReplaceAll, rfIgnoreCase]);
    Edit_Name_Game.Text:= STR;
  end;

end;

// Клик на Button Png
procedure TForm1.EditButton_Path_To_Png_OnButtonClick(Sender: TObject);
var
  OD: TOpenDialog;
begin
  OD := TOpenDialog.Create(Self);
  if OD.Execute then
  begin
    Image_Preview.Picture.LoadFromFile(OD.FileName);
    EditButton_Path_To_Png.Text:= OD.FileName;
  end;
end;

// Собрать PMD файл
procedure TForm1.Button_Build_File_OnClick(Sender: TObject);
var
  array_header : Array[0..519] of Byte;
  i: Integer;
  name_game : String;
  length_name_game: SizeInt;
  // Переменные для перевода из Integer в Hex
  Int2Hex_size_png_int : Integer;
  Int2Hex_size_png_hex : TByteArray absolute Int2Hex_size_png_int;
  Int2Hex_size_gen_int : Integer;
  Int2Hex_size_gen_hex : TByteArray absolute Int2Hex_size_gen_int;
  //
  MemoryStream_HEADER : TMemoryStream;
  FileStream_PNG : TFileStream;
  FileStream_PMD : TFileStream;
  FileStream_GEN : TFileStream;
begin
  // Инициализация потоков
  //MemoryStream_HEADER : TMemoryStream;
  //FileStream_PNG : TFileStream;
  //FileStream_PMD : TFileStream;
  //FileStream_GEN : TFileStream;

  // Получаем Имя игры
  name_game := ExtractFileName(Edit_Name_Game.Text);

  // Получаем количество знаков в имени
  length_name_game := Length(name_game);

  // Создаем заголовок в 512 байт
  // Если есть буквы то записываем их иначе записываем нули
  for i := 0 to 511 do
  begin
    if length_name_game > i then
    begin
         array_header[i] := Byte(name_game[i + 1]);
    end
       else
    begin
         array_header[i] := Byte($00);
    end;
  end;

  // Получаем PNG в потоке
  FileStream_PNG := TFileStream.Create(EditButton_Path_To_Png.Text, fmOpenRead);

  // Получаем размер png
  Int2Hex_size_png_int := FileStream_PNG.Size;

   // Записываем размер PNG в HEADER
  array_header[512] := Int2Hex_size_png_hex[0];
  array_header[513] := Int2Hex_size_png_hex[1];
  array_header[514] := Int2Hex_size_png_hex[2];
  array_header[515] := Int2Hex_size_png_hex[3];

  // Получаем GEN в потоке
  FileStream_GEN := TFileStream.Create(EditButton_Path_To_Games.Text, fmOpenRead);

  // Получаем размер GEN
  Int2Hex_size_gen_int := FileStream_GEN.Size;

  // Записываем размер GEN в HEADER
  array_header[516] := Int2Hex_size_gen_hex[0];
  array_header[517] := Int2Hex_size_gen_hex[1];
  array_header[518] := Int2Hex_size_gen_hex[2];
  array_header[519] := Int2Hex_size_gen_hex[3];

  // Копируем массив заголовка в поток
  MemoryStream_HEADER := TMemoryStream.Create;
  MemoryStream_HEADER.Write(array_header, 520);

  // Создаем файл PMD
  FileStream_PMD := TFileStream.Create( name_game + '.pmd', fmCreate);
  // Копируем поток HEADER
  MemoryStream_HEADER.Position := 0;
  FileStream_PMD.CopyFrom(MemoryStream_HEADER, MemoryStream_HEADER.Size);
  // Копируем поток PNG
  FileStream_PNG.Position := 0;
  FileStream_PMD.CopyFrom(FileStream_PNG, FileStream_PNG.Size);
  // Копируем поток GEN
  FileStream_GEN.Position := 0;
  FileStream_PMD.CopyFrom(FileStream_GEN, FileStream_GEN.Size);

  // Чистим память
  MemoryStream_HEADER.Free;
  FileStream_PMD.Free;
  FileStream_PNG.Free;
  FileStream_GEN.Free;

  // Сообщение что все готово
  ShowMessage('PMD файл готов!');
end;

// Сбросить все настройки
procedure TForm1.Button_Clear_AllClick(Sender: TObject);
begin
  Edit_Name_Game.Clear;
  EditButton_Path_To_Games.Clear;
  EditButton_Path_To_Png.Clear;
  Image_Preview.Picture.Clear;
end;



end.

