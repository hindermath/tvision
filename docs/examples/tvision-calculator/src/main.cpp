#define Uses_TApplication
#define Uses_TButton
#define Uses_TDeskTop
#define Uses_TDialog
#define Uses_TDrawBuffer
#define Uses_TEvent
#define Uses_TPalette
#define Uses_TRect
#define Uses_TStaticText
#define Uses_TView
#include <tvision/tv.h>

#include "calculator_engine.h"

#include <algorithm>
#include <array>
#include <string>

namespace
{

constexpr ushort cmFirstCalculatorButton = 2000;

struct ButtonDefinition
{
    const char *label;
    char key;
    short x;
    short y;
    short width;
};

constexpr std::array<ButtonDefinition, 17> buttons {{
    {"~C~", 'C', 2, 5, 7},
    {"~/~", '/', 10, 5, 7},
    {"~*~", '*', 18, 5, 7},
    {"~-~", '-', 26, 5, 7},
    {"~7~", '7', 2, 7, 7},
    {"~8~", '8', 10, 7, 7},
    {"~9~", '9', 18, 7, 7},
    {"~+~", '+', 26, 7, 7},
    {"~4~", '4', 2, 9, 7},
    {"~5~", '5', 10, 9, 7},
    {"~6~", '6', 18, 9, 7},
    {"~=~", '=', 26, 9, 7},
    {"~1~", '1', 2, 11, 7},
    {"~2~", '2', 10, 11, 7},
    {"~3~", '3', 18, 11, 7},
    {"~0~", '0', 2, 13, 15},
    {"~.~", '.', 18, 13, 7}
}};

class CalculatorDisplay final : public TView
{
public:
    explicit CalculatorDisplay(TRect &bounds) : TView(bounds)
    {
    }

    void setText(const std::string &newText)
    {
        text = newText;
        drawView();
    }

    void draw() override
    {
        TDrawBuffer buffer;
        const TColorAttr color = getColor(1);
        buffer.moveChar(0, ' ', color, size.x);

        const short start = std::max<short>(1, size.x - short(text.size()) - 1);
        buffer.moveStr(start, text.c_str(), color);
        writeLine(0, 0, size.x, 1, buffer);
    }

    TPalette &getPalette() const override
    {
        static TPalette palette("\x13", 1);
        return palette;
    }

private:
    std::string text {"0"};
};

class CalculatorDialog final : public TDialog
{
public:
    CalculatorDialog() :
        TWindowInit(&CalculatorDialog::initFrame),
        TDialog(TRect(0, 0, 36, 18), "tvision Calculator")
    {
        options |= ofFirstClick;

        TRect displayBounds(3, 2, 33, 3);
        display = new CalculatorDisplay(displayBounds);
        insert(display);

        insert(new TStaticText(
            TRect(3, 3, 33, 4),
            "Keys: 0-9 . + - * / = Enter"
        ));

        insert(new TStaticText(
            TRect(3, 16, 33, 17),
            "C clears | Esc closes"
        ));

        for (std::size_t index = 0; index < buttons.size(); ++index)
        {
            const ButtonDefinition &button = buttons[index];
            insert(new TButton(
                TRect(button.x, button.y, button.x + button.width, button.y + 2),
                button.label,
                cmFirstCalculatorButton + ushort(index),
                bfNormal
            ));
        }

        refreshDisplay();
    }

    void handleEvent(TEvent &event) override
    {
        if (event.what == evKeyDown)
        {
            const char key = event.keyDown.charScan.charCode;
            if (isCalculatorKey(key))
            {
                engine.press(key);
                refreshDisplay();
                clearEvent(event);
                return;
            }
        }
        else if (event.what == evCommand &&
                 event.message.command >= cmFirstCalculatorButton &&
                 event.message.command < cmFirstCalculatorButton + buttons.size())
        {
            const std::size_t index =
                event.message.command - cmFirstCalculatorButton;
            engine.press(buttons[index].key);
            refreshDisplay();
            clearEvent(event);
            return;
        }

        TDialog::handleEvent(event);
    }

private:
    calculator::Engine engine;
    CalculatorDisplay *display {nullptr};

    static bool isCalculatorKey(char key)
    {
        return (key >= '0' && key <= '9') || key == '.' || key == '+' ||
               key == '-' || key == '*' || key == '/' || key == '=' ||
               key == '\r' || key == '\n' || key == 'C' || key == 'c';
    }

    void refreshDisplay()
    {
        display->setText(engine.display());
    }
};

class Application final : public TApplication
{
public:
    Application() noexcept :
        TProgInit(
            &Application::initStatusLine,
            &Application::initMenuBar,
            &Application::initDeskTop
        )
    {
    }

    ~Application() override = default;
};

} // namespace

int main()
{
    Application application;
    auto *calculatorDialog = new CalculatorDialog;
    application.deskTop->execView(calculatorDialog);
    TObject::destroy(calculatorDialog);
    return 0;
}
