#ifndef TVISION_CALCULATOR_ENGINE_H
#define TVISION_CALCULATOR_ENGINE_H

#include <cstddef>
#include <string>

namespace calculator
{

class Engine final
{
public:
    Engine();

    void press(char key);
    void clear();

    const std::string &display() const noexcept;
    bool hasError() const noexcept;

private:
    static constexpr std::size_t maxEntryLength = 15;

    std::string entry;
    long double accumulator {0};
    char pendingOperator {'\0'};
    bool enteringNumber {false};
    bool resultShown {false};
    bool errorState {false};

    void inputDigit(char digit);
    void inputDecimalPoint();
    void selectOperator(char operation);
    void calculateResult();
    bool applyPending(long double rightOperand);
    void beginFreshEntryIfNeeded();
    void setError();

    long double currentValue() const;
    void showValue(long double value);
    static std::string formatValue(long double value);
};

} // namespace calculator

#endif // TVISION_CALCULATOR_ENGINE_H
