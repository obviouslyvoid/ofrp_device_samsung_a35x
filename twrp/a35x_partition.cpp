/*
 * a35x device hooks for TWRP/OrangeFox (TARGET_RECOVERY_TWRP_LIB).
 *
 * Samsung's Weaver daemon (hermesd, started for data decryption) keeps its
 * working directory and files open in /data/vendor/gatekeeper. That keeps the
 * metadata-encrypted userdata device busy, so Format Data cannot unmount /data
 * or remove the dm device. Stop it before the encryption wipe.
 */
#include <chrono>
#include <string>

#include <android-base/properties.h>

#include "partitions.hpp"
#include "twcommon.h"

namespace {
constexpr char kHermesService[] = "a35x-hermes";

void StopService(const char* name) {
    const std::string state_prop = std::string("init.svc.") + name;
    const std::string state = android::base::GetProperty(state_prop, "");
    if (state.empty() || state == "stopped")
        return;
    LOGINFO("a35x: stopping %s before wiping /data\n", name);
    android::base::SetProperty("ctl.stop", name);
    if (!android::base::WaitForProperty(state_prop, "stopped", std::chrono::seconds(5)))
        LOGINFO("a35x: %s did not stop in time\n", name);
}
}  // namespace

class A35xPartition : public BasePartition {
  public:
    bool PreWipeEncryption() override {
        StopService(kHermesService);
        return true;
    }
};

BasePartition* make_partition() {
    return new A35xPartition();
}
