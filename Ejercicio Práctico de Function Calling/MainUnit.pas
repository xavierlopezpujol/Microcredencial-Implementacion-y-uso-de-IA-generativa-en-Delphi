unit MainUnit;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Edit, FMX.Layouts,
  FMX.ScrollBox, FMX.Memo, FMX.Objects, System.Generics.Collections,
  uMakerAi.Chat.AiConnection,
  uMakerAi.Chat.Ollama,
  uMakerAi.Core,
  UMakerAi.ParamsRegistry,
  mormot.core.text, uMakerAi.ToolFunctions, FMX.Memo.Types,
  SystemInfo,
  FibonacciUnit;

type
  TChatMessage = record
    Text: string;
    IsFromBot: Boolean;
    Timestamp: TDateTime;
  end;

  TForm1 = class(TForm)
    LayoutMain: TLayout;
    LayoutChat: TLayout;
    LayoutInput: TLayout;
    ScrollBoxChat: TScrollBox;
    LayoutInputControls: TLayout;
    ButtonSend: TButton;
    AiConn: TAiChatConnection;
    AiFunctions1: TAiFunctions;
    mmoPrompt: TMemo;
    procedure ButtonSendClick(Sender: TObject);
    procedure EditMessageKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
    procedure FormCreate(Sender: TObject);
    procedure AiFunctions1Functions0GetFechayHoraAction(Sender: TObject;
      FunctionAction: TFunctionActionItem; FunctionName: string;
      ToolCall: TAiToolsFunction; var Handled: Boolean);
    procedure AiFunctions1Functions1CalculaFibonacciAction(Sender: TObject;
      FunctionAction: TFunctionActionItem; FunctionName: string;
      ToolCall: TAiToolsFunction; var Handled: Boolean);
  private
    FMessages: TList<TChatMessage>;
    procedure AddMessage(const AText: string; AIsFromBot: Boolean);
    procedure RefreshChatDisplay;
    function GetAIResponse(const UserMessage: string): string;
    procedure CreateMessageBubble(const AMessage: TChatMessage; AParent: TScrollBox);
  public
    destructor Destroy; override;
  end;

var
  Form1: TForm1;

const
  OLLAMA_SERVER='192.168.1.63';

implementation

{$R *.fmx}


procedure TForm1.FormCreate(Sender: TObject);
begin
  FMessages := TList<TChatMessage>.Create;

  // Configure the form
  Caption := 'Chat App';
  ClientHeight := 600;
  ClientWidth := 400;

  // Configure main layout
  LayoutMain.Align := TAlignLayout.Client;
  LayoutMain.Margins.Rect := RectF(10, 10, 10, 10);

  // Configure chat layout
  LayoutChat.Parent := LayoutMain;
  LayoutChat.Align := TAlignLayout.Client;
  LayoutChat.Margins.Bottom := 60;

  // Configure scroll box for chat
  ScrollBoxChat.Parent := LayoutChat;
  ScrollBoxChat.Align := TAlignLayout.Client;
  ScrollBoxChat.ShowScrollBars := True;

  // Configure input layout
  LayoutInput.Parent := LayoutMain;
  LayoutInput.Align := TAlignLayout.Bottom;
  LayoutInput.Height := 50;
  LayoutInput.Margins.Top := 10;

  // Configure input controls layout
  LayoutInputControls.Parent := LayoutInput;
  LayoutInputControls.Align := TAlignLayout.Client;

  // Configure message input
  mmoPrompt.Parent := LayoutInputControls;
  mmoPrompt.Align := TAlignLayout.Client;
//  mmoPrompt.Margins.Right := 80;
  mmoPrompt.Height := 40;

  // Configure send button
  ButtonSend.Parent := LayoutInputControls;
  ButtonSend.Align := TAlignLayout.Right;
  ButtonSend.Width := 50;
  ButtonSend.Height := 40;
  ButtonSend.Text := 'Enviar';
//  ButtonSend.StyleLookup := 'actiontoolbuttonbordered';

  // Add welcome message from bot
  AddMessage('Hola! dime en que te puedo ayudar hoy?', True);

  self.Resize;
  // Set focus to the message input after form is created
  TThread.CreateAnonymousThread(
    procedure
    begin
      Sleep(100); // Small delay to ensure UI is fully initialized
      TThread.Synchronize(nil,
        procedure
        begin
          mmoPrompt.SetFocus;
        end);
    end
  ).Start;

  // set ollama params
  TAIChatfactory.Instance.RegisterUserParam('Ollama','URL',formatUTF8('http://%:11434/',[OLLAMA_SERVER]));
end;

destructor TForm1.Destroy;
begin
  FMessages.Free;
  inherited;
end;

procedure TForm1.AiFunctions1Functions0GetFechayHoraAction(Sender: TObject;
  FunctionAction: TFunctionActionItem; FunctionName: string;
  ToolCall: TAiToolsFunction; var Handled: Boolean);
begin
  ToolCall.Response := ShowSystemInfo;
  Handled := True;
end;

procedure TForm1.AiFunctions1Functions1CalculaFibonacciAction(Sender: TObject;
  FunctionAction: TFunctionActionItem; FunctionName: string;
  ToolCall: TAiToolsFunction; var Handled: Boolean);
var parametro , i : Integer;
    serie: TFibonacciArray;
    s : string;
begin
  parametro := ToolCall.Params.Values['Param1'].ToInteger;

  serie := CalcularFibonacci(parametro);
  s := 'Serie completa hasta ' + parametro.ToString +': ';
  for i := 0 to Length(serie) - 1 do
  begin
    s := s + serie[i].ToString;
    if i < Length(serie) - 1 then s := s + ', ';
  end;
  ToolCall.Response := s;

  Handled := True;
end;

procedure TForm1.ButtonSendClick(Sender: TObject);
var
  UserMessage: string;
  AIResponse: string;
begin
  UserMessage := Trim(mmoPrompt.Text);
  if UserMessage = '' then
    Exit;

  // Add user message
  TThread.CreateAnonymousThread(procedure
  begin
    TThread.Synchronize(nil,procedure
    begin
      // Clear input
      mmoPrompt.Lines.Clear;
      AddMessage(UserMessage, False);
    end);

    // Get and add bot response
    AIResponse := GetAIResponse(UserMessage);

    TThread.Synchronize(nil,procedure
    begin
      AddMessage(AIResponse, True);

      // Focus back to input
      mmoPrompt.SetFocus;
    end);
  end).Start;


end;

procedure TForm1.EditMessageKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
begin
  if Key = vkReturn then
  begin
    ButtonSendClick(nil);
    Key := 0; // Consume the key event
  end;
end;

procedure TForm1.AddMessage(const AText: string; AIsFromBot: Boolean);
var
  Message: TChatMessage;
begin
  Message.Text := AText;
  Message.IsFromBot := AIsFromBot;
  Message.Timestamp := Now;

  FMessages.Add(Message);
  RefreshChatDisplay;
end;

procedure TForm1.RefreshChatDisplay;
var
  i: Integer;
begin
  // Clear existing chat bubbles
  ScrollBoxChat.Content.DeleteChildren;

  // Add all messages in reverse order (newest first becomes newest last)
  for i := FMessages.Count - 1 downto 0 do
    CreateMessageBubble(FMessages[i], ScrollBoxChat);


  // Scroll to bottom to show latest messages
  TThread.CreateAnonymousThread(
    procedure
    begin
      Sleep(50); // Small delay to ensure content is rendered
      TThread.Synchronize(nil,
        procedure
        begin
          ScrollBoxChat.ViewportPosition := PointF(ScrollBoxChat.ViewportPosition.X, ScrollBoxChat.Height );
        end);
    end
  ).Start;
end;

procedure TForm1.CreateMessageBubble(const AMessage: TChatMessage; AParent: TScrollBox);
var
  BubbleLayout: TLayout;
  BubbleRect: TRectangle;
  MessageLabel: TLabel;
  TimeLabel: TLabel;
  BubbleHeight: Single;
  MessageHeight: Single;
begin
  // Create main bubble layout
  BubbleLayout := TLayout.Create(AParent);
  BubbleLayout.Parent := AParent;
  BubbleLayout.Align := TAlignLayout.Top;
  BubbleLayout.Height := 80; // Will be adjusted
  BubbleLayout.Margins.Top := 5;
  BubbleLayout.Margins.Bottom := 5;

  if AMessage.IsFromBot then
  begin
    // Bot message - align left
    BubbleLayout.Margins.Left := 10;
    BubbleLayout.Margins.Right := 80;
  end
  else
  begin
    // User message - align right
    BubbleLayout.Margins.Left := 80;
    BubbleLayout.Margins.Right := 10;
  end;

  // Create bubble rectangle
  BubbleRect := TRectangle.Create(BubbleLayout);
  BubbleRect.Parent := BubbleLayout;
  BubbleRect.Align := TAlignLayout.Client;
  BubbleRect.XRadius := 12;
  BubbleRect.YRadius := 12;
  BubbleRect.Stroke.Kind := TBrushKind.None;

  if AMessage.IsFromBot then
  begin
    // Bot bubble - light gray
    BubbleRect.Fill.Color := $FFE5E5E5;
  end
  else
  begin
    // User bubble - blue
    BubbleRect.Fill.Color := $FF007AFF;
  end;

  // Create message label
  MessageLabel := TLabel.Create(BubbleRect);
  MessageLabel.Parent := BubbleRect;
  MessageLabel.Align := TAlignLayout.Client;
  MessageLabel.Text := AMessage.Text;
  MessageLabel.WordWrap := True;
  MessageLabel.Margins.Rect := RectF(12, 8, 12, 20);

  if AMessage.IsFromBot then
    MessageLabel.FontColor := TAlphaColors.Black
  else
    MessageLabel.FontColor := TAlphaColors.White;

  // Create time label
  TimeLabel := TLabel.Create(BubbleRect);
  TimeLabel.Parent := BubbleRect;
  TimeLabel.Align := TAlignLayout.Bottom;
  TimeLabel.Height := 16;
  TimeLabel.Text := FormatDateTime('hh:nn', AMessage.Timestamp);
  TimeLabel.Font.Size := 10;
  TimeLabel.Margins.Rect := RectF(12, 0, 12, 4);

  if AMessage.IsFromBot then
  begin
    TimeLabel.FontColor := TAlphaColors.Gray;
    TimeLabel.TextAlign := TTextAlign.Leading;
  end
  else
  begin
    TimeLabel.FontColor := $FFCCCCCC;
    TimeLabel.TextAlign := TTextAlign.Trailing;
  end;

  // Calculate and set proper height
  MessageHeight := MessageLabel.Canvas.TextHeight(AMessage.Text) + 20; // Some padding
  if MessageHeight < 40 then
    MessageHeight := 40;

  BubbleHeight := MessageHeight + 20; // Space for timestamp
  BubbleLayout.Height := BubbleHeight;
end;

function TForm1.GetAIResponse(const UserMessage: string): string;
var Prompt : string;
begin
  AiConn.UpdateParamsFromRegistry;
  AiConn.Params.Values['Tool_Active'] := 'True';
  AiConn.Params.Values['model'] := 'llama3.1:8B';
//  AiConn.Params.Values['model'] := 'mistral';  //retorna [{"name":"ObtenerInfoSistema"}]
//  AiConn.Params.Values['model'] := 'phi3';  //No tool calling

  Prompt := mmoPrompt.Lines.Text;
  Result := AiConn.AddMessageAndRun(Prompt, 'user', []);
end;

end.


