#include <unity.h>

#include "sensor_math.h"

void test_median3_sorts_any_order() {
    TEST_ASSERT_EQUAL_UINT16(20, sensorMedian3(10, 20, 30));
    TEST_ASSERT_EQUAL_UINT16(20, sensorMedian3(30, 10, 20));
    TEST_ASSERT_EQUAL_UINT16(20, sensorMedian3(20, 30, 10));
}

void test_calibration_applies_offset_and_clamps_to_zero() {
    TEST_ASSERT_EQUAL_UINT16(115, sensorApplyCalibration(120, -5, 400));
    TEST_ASSERT_EQUAL_UINT16(0, sensorApplyCalibration(5, -20, 400));
}

void test_calibration_preserves_no_obstacle_and_enforces_range() {
    TEST_ASSERT_EQUAL_UINT16(
        SENSOR_NO_OBSTACLE_CM,
        sensorApplyCalibration(SENSOR_NO_OBSTACLE_CM, -100, 400)
    );
    TEST_ASSERT_EQUAL_UINT16(
        SENSOR_NO_OBSTACLE_CM,
        sensorApplyCalibration(401, 0, 400)
    );
}

void test_active_sensor_filter() {
    TEST_ASSERT_TRUE(sensorIsEnabled(3, 0));
    TEST_ASSERT_TRUE(sensorIsEnabled(3, 1));
    TEST_ASSERT_TRUE(sensorIsEnabled(3, 2));
    TEST_ASSERT_TRUE(sensorIsEnabled(1, 1));
    TEST_ASSERT_FALSE(sensorIsEnabled(1, 0));
    TEST_ASSERT_FALSE(sensorIsEnabled(1, 2));
}

int main() {
    UNITY_BEGIN();
    RUN_TEST(test_median3_sorts_any_order);
    RUN_TEST(test_calibration_applies_offset_and_clamps_to_zero);
    RUN_TEST(test_calibration_preserves_no_obstacle_and_enforces_range);
    RUN_TEST(test_active_sensor_filter);
    return UNITY_END();
}
