/* Copyright 2021 Intel Corporation

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

#ifndef __DPDK_PSA_P4__
#define __DPDK_PSA_P4__

/**********************************************************************
 * Beginning of the part of this target-customized psa.p4 include file
 * that declares data plane widths for one particular target device.
 **********************************************************************/

/* Target device for which this section is customized:
 *
 * DPDK back end as implemented by p4c-dpdk in the repository
 * https://github.com/p4lang/p4c
 */

// BEGIN:DPDKCounter_extern
/// Indirect counter with n_counters independent counter values, where
/// every counter value has a data plane size specified by type W.

extern DPDKCounter<W, S> {
  DPDKCounter(bit<32> n_counters, PSA_CounterType_t type);
  void count(in S index, @optional in bit<32> increment);

  /*
  /// The control plane API uses 64-bit wide counter values.  It is
  /// not intended to represent the size of counters as they are
  /// stored in the data plane.  It is expected that control plane
  /// software will periodically read the data plane counter values,
  /// and accumulate them into larger counters that are large enough
  /// to avoid reaching their maximum values for a suitably long
  /// operational time.  A 64-bit byte counter increased at maximum
  /// line rate for a 100 gigabit port would take over 46 years to
  /// wrap.

  @ControlPlaneAPI
  {
    bit<64> read      (in S index);
    bit<64> sync_read (in S index);
    void set          (in S index, in bit<64> seed);
    void reset        (in S index);
    void start        (in S index);
    void stop         (in S index);
  }
  */
}
// END:DPDKCounter_extern

// DPDK does not support PACKETS metering if testcases still use
// packets metering type compiler converts it to bytes metering
// Hence execute method below always require pkt_len parameter.
extern DPDKMeter<S> {
  DPDKMeter(bit<32> n_meters, PSA_MeterType_t type);

  // Use this method call to perform a color aware meter update (see
  // RFC 2698). The color of the packet before the method call was
  // made is specified by the color parameter.
  PSA_MeterColor_t execute(in S index, in PSA_MeterColor_t color, in bit<32> pkt_len);

  // Use this method call to perform a color blind meter update (see
  // RFC 2698).  It may be implemented via a call to execute(index,
  // MeterColor_t.GREEN), which has the same behavior.
  PSA_MeterColor_t execute(in S index, in bit<32> pkt_len);

  /*
  @ControlPlaneAPI
  {
    reset(in MeterColor_t color);
    setParams(in S index, in MeterConfig config);
    getParams(in S index, out MeterConfig config);
  }
  */
}
// END:DPDKMeter_extern
#endif   // __DPDK_PSA_P4__
