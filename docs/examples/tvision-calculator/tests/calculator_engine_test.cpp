#include "calculator_engine.h"

#include <iostream>
#include <string>

namespace
{

int failures = 0;

void expectDisplay(
    const std::string &scenario,
    const std::string &keys,
    const std::string &expected
)
{
    calculator::Engine engine;
    for (char key : keys)
        engine.press(key);

    if (engine.display() != expected)
    {
        std::cerr << scenario << ": expected '" << expected << "', got '"
                  << engine.display() << "'\n";
        ++failures;
    }
}
void expectDivisionByZeroRecovery()
{
    calculator::Engine engine;
    for (char key : std::string("8/0="))
        engine.press(key);

    if (!engine.hasError() || engine.display() != "Error")
    {
        std::cerr << "division by zero did not enter the Error state\n";
        ++failures;
    }

    engine.press('7');
    if (engine.display() != "Error")
    {
        std::cerr << "Error state accepted input before C\n";
        ++failures;
    }

    engine.press('C');
    engine.press('7');
    if (engine.hasError() || engine.display() != "7")
    {
        std::cerr << "C did not restore calculator input\n";
        ++failures;
    }
}

} // namespace

int main()
{
    expectDisplay("addition", "2+3=", "5");
    expectDisplay("subtraction", "7-10=", "-3");
    expectDisplay("multiplication", "6*4=", "24");
    expectDisplay("division", "8/2=", "4");
    expectDisplay("decimal", "1.5+2.25=", "3.75");
    expectDisplay("single decimal point", "1..5", "1.5");
    expectDisplay("leading zero", "00042", "42");
    expectDisplay("immediate execution", "2+3*4=", "20");
    expectDisplay("operator replacement", "9+-3=", "6");
    expectDisplay("new input after result", "2+3=7", "7");
    expectDisplay("enter equals", "9/3\r", "3");
    expectDivisionByZeroRecovery();

    if (failures != 0)
        return 1;

    std::cout << "All calculator engine scenarios passed.\n";
    return 0;
}
